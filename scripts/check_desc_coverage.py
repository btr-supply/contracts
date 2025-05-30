#!/usr/bin/env python3
"""
Check desc.yml coverage for Solidity files

Finds all .sol files and checks which ones are missing from desc.yml
"""

import yaml
from pathlib import Path


def get_all_sol_files():
  """Get all .sol files in the project"""
  root = Path('.')
  sol_files = []

  for file in root.rglob('*.sol'):
    # Skip build artifacts and dependencies
    if any(skip in str(file) for skip in ['/out/', '/.deps/', '/arrakis-v2/']):
      continue
    sol_files.append(file)

  return sorted(sol_files)


def get_desc_entries():
  """Get all .sol file entries from desc.yml"""
  desc_path = Path('assets/desc.yml')
  if not desc_path.exists():
    return set()

  with open(desc_path) as f:
    desc = yaml.safe_load(f)

  entries = set()

  def collect_entries(node, base_path=""):
    if isinstance(node, dict):
      for key, value in node.items():
        if key.endswith('.sol'):
          entries.add(f"{base_path}/{key}" if base_path else key)
        elif isinstance(value, dict):
          new_path = f"{base_path}/{key}" if base_path else key
          collect_entries(value, new_path)

  # Collect from evm section
  if 'evm' in desc:
    collect_entries(desc['evm'], 'evm')

  return entries


def main():
  sol_files = get_all_sol_files()
  desc_entries = get_desc_entries()

  print(f"Found {len(sol_files)} .sol files")
  print(f"Found {len(desc_entries)} entries in desc.yml")

  missing = []
  for file in sol_files:
    # Convert to relative path from project root
    rel_path = str(file)
    if rel_path.startswith('./'):
      rel_path = rel_path[2:]

    if rel_path not in desc_entries:
      missing.append(rel_path)

  if missing:
    print(f"\n❌ Missing {len(missing)} files from desc.yml:")
    for file in sorted(missing):
      print(f"  - {file}")
  else:
    print("\n✅ All .sol files are covered in desc.yml")

  # Also check for entries in desc.yml that don't exist as files
  existing_files = {
      str(f)[2:] if str(f).startswith('./') else str(f)
      for f in sol_files
  }
  orphaned = []
  for entry in desc_entries:
    if entry not in existing_files:
      orphaned.append(entry)

  if orphaned:
    print(f"\n⚠️  Found {len(orphaned)} orphaned entries in desc.yml:")
    for entry in sorted(orphaned):
      print(f"  - {entry}")


if __name__ == '__main__':
  main()
