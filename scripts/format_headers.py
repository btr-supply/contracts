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


# Function to strip existing headers
def strip_header(lines, ext):
  shebang = ''
  if lines and lines[0].startswith('#!'):
    shebang = lines.pop(0)
  if ext == '.sol':
    # Remove SPDX, pragmas, and leading blanks/comments
    while lines and (lines[0].startswith('// SPDX-License-Identifier') or
                     lines[0].startswith('pragma ') or not lines[0].strip()):
      lines.pop(0)
    # Remove NatSpec block
    if lines and lines[0].startswith('/**'):
      while lines and not lines[0].strip().endswith('*/'):
        lines.pop(0)
      if lines:
        lines.pop(0)
      while lines and not lines[0].strip():
        lines.pop(0)
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
  tpl = templates.get(ext)
  if not tpl or not fp.is_file():
    skipped += 1
    continue
  # Gather metadata for this file
  node = desc
  for part in fp.relative_to(ROOT).parts:
    node = node.get(part, {}) if isinstance(node, dict) else {}
  data = {
      **defaults,
      **{
          k: node.get(k, '')
          for k in ('title', 'short_desc', 'desc', 'dev_comment')
      }
  }
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
