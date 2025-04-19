#!/usr/bin/env bash
set -euo pipefail

# Usage: release.sh <major|minor|patch>
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <major|minor|patch>" >&2
  exit 1
fi

TYPE=$1
# Run Python script and capture the last line (the new version)
VER=$(uv run python scripts/release.py "$TYPE" | tail -n1)

git add pyproject.toml CHANGELOG.md
git commit -m "[ops] Release v$VER"
git tag "v$VER"
git push origin main --tags
