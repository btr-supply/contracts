"""
SPDX-License-Identifier: MIT
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@title Format Source Headers Script - Updates file headers using templates and descriptions
@copyright 2025
@notice Python script that reads descriptions from assets/desc.yml and applies them to source file headers (.sol, .py, .sh)
using templates from assets/headers/

@dev Maintains consistency in file headers across the project
@author BTR Team
"""

#!/usr/bin/env python3
import sys
import re
import yaml
from pathlib import Path
from string import Template

# Paths
ROOT = Path(__file__).parent.parent
DESC_PATH = ROOT / 'assets' / 'desc.yml'
HDR_DIR = ROOT / 'assets' / 'headers'
SCRIPTS_DIR = ROOT / 'scripts'
EVM_DIR = ROOT / 'evm'

# Load metadata
desc = yaml.safe_load(DESC_PATH.read_text()) or {}
defaults = desc.get('defaults', {})

# Load header templates
templates = {}
for ext in ('sol', 'py', 'sh'):
  tpl_file = HDR_DIR / f"{ext}.txt"
  if tpl_file.is_file():
    text = tpl_file.read_text()
    pattern = re.compile(r"\{\{\s*(\w+)\s*\}\}")
    txt = pattern.sub(r'${\1}', text)
    templates[f'.{ext}'] = Template(txt)

# Collect target files
files = []
# Off-chain scripts
for name in desc.get('scripts', {}):
  if name.endswith(('.py', '.sh')):
    files.append(SCRIPTS_DIR / name)


# On-chain EVM sources
def collect_sols(node, base):
  for k, v in node.items():
    path = base / k
    if k.endswith('.sol'):
      files.append(path)
    elif isinstance(v, dict):
      collect_sols(v, path)


collect_sols(desc.get('evm', {}), EVM_DIR)

# Also collect interface files directly
interfaces_dir = EVM_DIR / 'interfaces'
if interfaces_dir.exists():
  for interface_file in interfaces_dir.rglob('*.sol'):
    if interface_file not in files:
      files.append(interface_file)


def is_interface_file(file_path):
  """Check if a file is an interface file"""
  return 'interfaces' in str(file_path)


def create_interface_header(sol_version):
  """Create minimal header for interface files"""
  return f"// SPDX-License-Identifier: MIT\npragma solidity {sol_version};"


# Function to strip existing headers
def strip_header(lines, ext):
  shebang = ''
  if lines and lines[0].startswith('#!'):
    shebang = lines.pop(0)

  if ext == '.sol':
    # For Solidity files, we need to remove ALL header-like content throughout the file
    i = 0
    while i < len(lines):
      line = lines[i].strip()

      # Always remove SPDX and pragma lines
      if (line.startswith('// SPDX-License-Identifier')
          or line.startswith('pragma ')):
        lines.pop(i)
        continue

      # Remove blank lines at the beginning
      if not line and i < 10:  # Only remove blank lines near the top
        lines.pop(i)
        continue

      # Remove NatSpec comment blocks that contain header keywords
      if line.startswith('/*'):
        # Look ahead to see if this block contains header content
        block_content = []
        j = i

        # Collect the entire block
        while j < len(lines):
          block_content.append(lines[j])
          if lines[j].strip().endswith('*/'):
            break
          j += 1

        # Check if this block contains header keywords
        block_text = ' '.join(block_content).lower()
        is_header_block = any(keyword in block_text for keyword in [
            '@title', '@copyright', '@notice', '@dev', '@author',
            '@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
        ])

        if is_header_block:
          # Remove the entire block
          for _ in range(j - i + 1):
            if i < len(lines):
              lines.pop(i)
          continue
        else:
          # Keep this block, move to next line
          i += 1
          continue

      # Remove single-line comments that look like headers
      if line.startswith('//') and any(
          keyword in line.lower() for keyword in
          ['title', 'author', 'notice', 'dev', 'copyright', 'spdx']):
        lines.pop(i)
        continue

      # Move to next line
      i += 1

  elif ext == '.py':
    # Remove SPDX, leading blanks
    while lines and 'SPDX-License-Identifier' in lines[0]:
      lines.pop(0)
    while lines and not lines[0].strip():
      lines.pop(0)
    # Remove module docstring
    if lines and (lines[0].startswith('"""') or lines[0].startswith("'''")):
      delim = lines.pop(0)[:3]
      while lines and delim not in lines[0]:
        lines.pop(0)
      if lines:
        lines.pop(0)
  elif ext == '.sh':
    # Remove leading comments/blanks
    while lines and (lines[0].lstrip().startswith('#')
                     or not lines[0].strip()):
      lines.pop(0)

  if shebang:
    lines.insert(0, shebang)
  return lines


# Process files
processed = skipped = errors = 0
for fp in files:
  ext = fp.suffix
  if not fp.is_file():
    skipped += 1
    continue

  # Handle interface files specially
  if ext == '.sol' and is_interface_file(fp):
    header = create_interface_header(defaults.get('sol_version', '0.8.29'))

    original = fp.read_text()
    lines = original.splitlines()
    body_lines = strip_header(lines[:], ext)
    body = '\n'.join(body_lines).lstrip('\n')
    new_content = f"{header}\n\n{body}\n"

    if new_content != original:
      try:
        fp.write_text(new_content)
        print(f"✔️ Processed interface {fp.relative_to(ROOT)}")
        processed += 1
      except Exception as e:
        print(f"❌ Error {fp.relative_to(ROOT)}: {e}")
        errors += 1
    else:
      skipped += 1
    continue

  # Handle regular files with full templates
  tpl = templates.get(ext)
  if not tpl:
    skipped += 1
    continue

  # Gather metadata for this file
  node = desc
  for part in fp.relative_to(ROOT).parts:
    node = node.get(part, {}) if isinstance(node, dict) else {}

  # Start with defaults
  data = dict(defaults)

  # Override with node-specific values, but only if they exist and are not empty
  for k in ('title', 'short_desc', 'desc', 'dev_comment', 'license'):
    if k in node and node[
        k]:  # Only override if key exists and has a non-empty value
      data[k] = node[k]

  # Build header dynamically based on available fields
  if ext == '.sol':
    header_lines = [
        f"// SPDX-License-Identifier: {data.get('license', 'MIT')}",
        f"pragma solidity {data.get('sol_version', '0.8.29')};", "", "/*",
        " * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
        " * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@",
        " * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@",
        " * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@",
        " * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@",
        " * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@",
        " * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", " *"
    ]

    # Add title line (always present)
    title = data.get('title', '')
    short_desc = data.get('short_desc', '')
    if title and short_desc:
      header_lines.append(f" * @title {title} - {short_desc}")
    elif title:
      header_lines.append(f" * @title {title}")

    # Add copyright (always present)
    header_lines.append(" * @copyright 2025")

    # Add notice if desc exists
    if data.get('desc'):
      header_lines.append(f" * @notice {data['desc']}")

    # Add dev comment if exists
    if data.get('dev_comment'):
      header_lines.append(f" * @dev {data['dev_comment']}")

    # Add author (always present)
    header_lines.append(f" * @author {data.get('author', 'BTR Team')}")
    header_lines.append(" */")

    header = '\n'.join(header_lines)
  else:
    # For non-Solidity files, use the template as before
    header = tpl.substitute(data).rstrip()

  original = fp.read_text()
  lines = original.splitlines()
  body_lines = strip_header(lines[:], ext)
  body = '\n'.join(body_lines).lstrip('\n')
  new_content = f"{header}\n\n{body}\n"

  if new_content != original:
    try:
      fp.write_text(new_content)
      print(f"✔️ Processed {fp.relative_to(ROOT)}")
      processed += 1
    except Exception as e:
      print(f"❌ Error {fp.relative_to(ROOT)}: {e}")
      errors += 1
  else:
    skipped += 1

print(f"Result: {processed} processed, {skipped} skipped, {errors} errors")
sys.exit(1 if errors else 0)
