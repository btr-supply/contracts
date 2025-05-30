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
# @title Check Branch Script - Verifies the current Git branch name
# @copyright 2025
# @notice Checks if the current Git branch matches an expected name (e.g., 'main'). Used in CI/CD or pre-commit hooks
# @dev Simple Git utility script
# @author BTR Team
#

set -euo pipefail

exp=${1:-main}
curr=$(git rev-parse --abbrev-ref HEAD)
printf "⏳ verifying branch '%s'..." "$exp"
if [ "$curr" = "$exp" ]; then
  printf "✔ branch '%s' OK    \n" "$curr"
else
  printf "❌ branch '%s' (expected '%s')\n" "$curr" "$exp" >&2
  exit 1
fi
exit 0
