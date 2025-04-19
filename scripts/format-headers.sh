#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || { echo "Error: Cannot cd to project root"; exit 1; }

# Load default metadata into shell variables (defaults_licence, defaults_author, defaults_sol_version, ...)
eval "$(yq -o sh assets/desc.yml)"
TEMPLATE="assets/headers/sol.txt"

echo "Formatting facet headers..."

# Iterate over each abstract facet defined
yq -I0 -r '.evm.src.facets.abstract | keys[]' assets/desc.yml | while read -r file; do
  target="evm/src/facets/abstract/$file"
  [ -f "$target" ] || continue
  printf "Processing %-30s" "$file"

  # Extract metadata fields
  title=$(yq -r ".evm.src.facets.abstract.\"$file\".title" assets/desc.yml)
  sdesc=$(yq -r ".evm.src.facets.abstract.\"$file\".short_desc" assets/desc.yml)
  desc=$(yq -r ".evm.src.facets.abstract.\"$file\".desc" assets/desc.yml)
  dev=$(yq -r ".evm.src.facets.abstract.\"$file\".dev_comment" assets/desc.yml)

  # Apply header template with substitutions
  sed \
    -e "s/{{ title }}/$title/g" \
    -e "s/{{ short_desc }}/$sdesc/g" \
    -e "s/{{ desc }}/$desc/g" \
    -e "s/{{ dev_comment }}/$dev/g" \
    -e "s/{{ licence }}/$defaults_licence/g" \
    -e "s/{{ author }}/$defaults_author/g" \
    -e "s/{{ sol_version }}/$defaults_sol_version/g" \
    "$TEMPLATE" > "$target.tmp"

  # Append the existing contract code from the first solidity keyword onward
  sed -n '/^\(contract\|struct\|library\|\/\/\/\|import\)/,$p' "$target" >> "$target.tmp"

  mv "$target.tmp" "$target" && status=0 || status=1

  if [ $status -eq 0 ]; then
    printf "\r✔️ %s\n" "$file"
  else
    printf "\r❌ %s\n" "$file"
  fi
done

echo "Header formatting complete."
