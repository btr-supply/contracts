#!/usr/bin/env python3
"""
Solidity Import Organizer

Organizes imports in order: Types/Events/Errors, Libraries, Interfaces, Abstract, Contracts
Usage: python scripts/organize_imports.py
"""

import re
from pathlib import Path


def categorize_import(path: str, items: list) -> int:
  """Return category: 1=Types/Events/Errors, 2=Libraries, 3=Interfaces, 4=Abstract, 5=Contracts"""
  # Types, Events, Errors
  if any(x in path for x in ['Types.sol', 'Events.sol', 'Errors.sol']) or \
     any(x in items for x in ['TokenType', 'FeeType', 'AccessControl', 'Diamond', 'Range']):
    return 1

  # Libraries
  if '@libraries' in path or './Lib' in path or '/utils/' in path or \
     any(x in path for x in ['SafeERC20', 'Math.sol', 'Arrays.sol', 'Address.sol']):
    return 2

  # Interfaces
  if path.startswith('I') or '/I' in path or 'interface' in path.lower():
    return 3

  # Abstract contracts
  if 'abstract' in path.lower() or 'Abstract' in path or 'Base' in path:
    return 4

  # Contracts
  return 5


def organize_file(file_path: Path):
  """Organize imports in a single Solidity file"""
  try:
    content = file_path.read_text()
    lines = content.split('\n')

    imports = []
    other_lines = []
    current_import = ""
    in_multiline_import = False

    for line in lines:
      stripped = line.strip()

      # Handle multi-line imports
      if stripped.startswith('import ') or in_multiline_import:
        current_import += line + '\n'
        in_multiline_import = True

        if stripped.endswith(';'):
          # Parse the complete import
          import_text = current_import.strip()
          match = re.search(
              r'import\s+(?:{([^}]+)}\s+from\s+)?["\']([^"\']+)["\']',
              import_text, re.DOTALL)
          if match:
            items_str = match.group(1) or ''
            items = [x.strip() for x in items_str.split(',')
                     if x.strip()] if items_str else []
            path = match.group(2)
            category = categorize_import(path, items)
            is_oz = '@openzeppelin' in path
            imports.append((category, is_oz, import_text))

          current_import = ""
          in_multiline_import = False
      else:
        other_lines.append(line)

    if not imports:
      return False

    # Sort imports: by category, then OpenZeppelin first, then alphabetically
    imports.sort(key=lambda x: (x[0], not x[1], x[2]))

    # Find where to insert imports (after SPDX and pragma)
    insert_idx = 0
    for i, line in enumerate(other_lines):
      stripped = line.strip()
      if not (stripped.startswith('// SPDX-License-Identifier')
              or stripped.startswith('pragma ') or stripped == ''):
        insert_idx = i
        break

    # Insert organized imports
    import_lines = [imp[2] for imp in imports]
    new_lines = (other_lines[:insert_idx] + [''] + import_lines + [''] +
                 other_lines[insert_idx:])

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
  """Organize imports in all Solidity files"""
  sol_files = list(Path('.').rglob('*.sol'))
  sol_files = [
      f for f in sol_files if '/out/' not in str(f) and '/.deps/' not in str(f)
  ]

  organized = 0
  for file_path in sol_files:
    if organize_file(file_path):
      organized += 1

  print(f"Organized imports in {organized}/{len(sol_files)} files")


if __name__ == '__main__':
  main()
