#!/bin/bash -e
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

echo "Formatting staged files..."
total=0
git diff --name-only --cached --diff-filter=ACMR | while read -r f; do
  printf "Processing %-30s" "$f"
  case $f in *.py) uv run yapf -i "$f" >/dev/null;; evm/*.sol) forge fmt "$f" >/dev/null;; *) continue;; esac && {
    printf "\r✔️ %s\n" "$f"; git add "$f"; total=$((total+1))
  } || printf "\r❌ %s\n" "$f"
done

echo "Formatted $total file(s)"
