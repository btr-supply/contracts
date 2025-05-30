#!/usr/bin/env python3
"""
Solidity Header Stripper

Removes SPDX license identifiers and @title/@notice/@dev/@author comments
Usage: python scripts/strip_headers.py
"""

from pathlib import Path


def strip_file(file_path: Path):
  """Strip headers and comments from a single Solidity file"""
  try:
    content = file_path.read_text()
    lines = content.split('\n')

    new_lines = []
    in_comment_block = False
    skip_until_contract = False

    for line in lines:
      stripped = line.strip()

      # Skip SPDX license
      if 'SPDX-License-Identifier' in line:
        continue

      # Skip comment blocks that contain @title, @notice, @dev, @author
      if stripped.startswith('/*') and any(
          x in content[content.find(line):content.find(line) + 500]
          for x in ['@title', '@notice', '@dev', '@author']):
        in_comment_block = True
        continue

      if in_comment_block:
        if stripped.endswith('*/'):
          in_comment_block = False
        continue

      # Skip single-line comments with @title, @notice, etc.
      if stripped.startswith('//') and any(
          x in stripped for x in ['@title', '@notice', '@dev', '@author']):
        continue

      # Skip duplicate title comments
      if any(x in stripped.lower()
             for x in ['* @title', '* @notice', '* @dev', '* @author']):
        skip_until_contract = True
        continue

      if skip_until_contract and (stripped.startswith('contract ')
                                  or stripped.startswith('library ')
                                  or stripped.startswith('interface ')
                                  or stripped.startswith('abstract ')):
        skip_until_contract = False
        new_lines.append(line)
        continue

      if skip_until_contract:
        continue

      new_lines.append(line)

    # Clean up excessive empty lines
    cleaned_lines = []
    prev_empty = False
    for line in new_lines:
      if line.strip() == '':
        if not prev_empty:
          cleaned_lines.append(line)
        prev_empty = True
      else:
        cleaned_lines.append(line)
        prev_empty = False

    new_content = '\n'.join(cleaned_lines).rstrip() + '\n'
    file_path.write_text(new_content)
    return True

  except Exception as e:
    print(f"Error processing {file_path}: {e}")
    return False


def main():
  """Strip headers from all Solidity files"""
  sol_files = list(Path('.').rglob('*.sol'))
  sol_files = [
      f for f in sol_files if '/out/' not in str(f) and '/.deps/' not in str(f)
  ]

  stripped = 0
  for file_path in sol_files:
    if strip_file(file_path):
      stripped += 1

  print(f"Stripped headers from {stripped}/{len(sol_files)} files")


if __name__ == '__main__':
  main()
