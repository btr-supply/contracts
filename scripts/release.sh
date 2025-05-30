#
# SPDX-License-Identifier: BUSL-1.1
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
# @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
# @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
# @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
# @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
# @title Release Runner Script - Orchestrates the release process
# @copyright 2025
# @notice Executes the release helper Python script (`release.py`) and potentially other release tasks like tagging
# @dev Top-level script for creating a new release
# @author BTR Team
#

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
