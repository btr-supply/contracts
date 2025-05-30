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
# @title Test Runner Script - Executes Foundry tests
# @copyright 2025
# @notice Runs the Solidity test suite using `forge test`
# @dev Standard script for running unit and integration tests
# @author BTR Team
#

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../evm" || exit 1
echo -e "\n>> Running tests\n"
forge test -vvv "$@"
exit_code=$?
echo -e "\n>> $([[ $exit_code -eq 0 ]] && echo '✔️ Success' || echo '⚠️ Failed')\n"
exit $exit_code
