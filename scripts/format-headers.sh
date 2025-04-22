#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "Error: Cannot cd to project root"; exit 1; }

# Load default metadata into shell variables (defaults_licence, defaults_author, defaults_sol_version, ...)
eval "$(yq '.defaults | with_entries(.key = "defaults_" + .key)' -o sh assets/desc.yml)"
TEMPLATE="assets/headers/sol.txt"

echo "Formatting Solidity file headers based on assets/desc.yml..."

# Iterate over all paths in desc.yml that end with a key matching *.sol
yq 'paths(scalars) | select(.[-1] | test("\.sol$")) | join(".")' assets/desc.yml | while read -r yaml_path; do
  # Construct file system path from YAML path (e.g., evm.src.libs.Utils.sol -> evm/src/libs/Utils.sol)
  # This simple substitution works as long as no directory names contain '.'
  target_file=$(echo "$yaml_path" | sed 's#\.#/#g')

  # Check if the target file actually exists
  if [ ! -f "$target_file" ]; then
    printf "🟡 Skipping %-40s (File not found, but listed in desc.yml)\n" "$target_file"
    continue
  fi

  printf "Processing %-40s" "$target_file"

  # Extract metadata fields using the full YAML path. Handle nulls gracefully.
  title=$(yq -r ".$yaml_path.title // """ assets/desc.yml)
  sdesc=$(yq -r ".$yaml_path.short_desc // """ assets/desc.yml)
  desc=$(yq -r ".$yaml_path.desc // """ assets/desc.yml)
  dev=$(yq -r ".$yaml_path.dev_comment // """ assets/desc.yml)

  # Apply header template with substitutions
  sed \
    -e "s/{{ *title *}}/$(echo "$title" | sed 's/[&/\\]/\\&/g')/g" \
    -e "s/{{ *short_desc *}}/$(echo "$sdesc" | sed 's/[&/\\]/\\&/g')/g" \
    -e "s/{{ *desc *}}/$(echo "$desc" | sed 's/[&/\\]/\\&/g')/g" \
    -e "s/{{ *dev_comment *}}/$(echo "$dev" | sed 's/[&/\\]/\\&/g')/g" \
    -e "s/{{ *licence *}}/$defaults_licence/g" \
    -e "s/{{ *author *}}/$defaults_author/g" \
    -e "s/{{ *sol_version *}}/$defaults_sol_version/g" \
    "$TEMPLATE" > "$target_file.tmp"

  # Append the existing contract code from the first relevant keyword onward, skipping original pragma
  sed -n '/^\(import\|contract\|interface\|library\|struct\|\/\/\/\)/,$p' "$target_file" >> "$target_file.tmp"

  # Replace original file with the updated temporary file
  if mv "$target_file.tmp" "$target_file"; then
    printf "\r✔️  Processed %-40s\n" "$target_file"
  else
    printf "\r❌ Error processing %-40s\n" "$target_file"
    # Optionally remove the temp file on error: rm -f "$target_file.tmp"
  fi

done

echo "Header formatting complete."
