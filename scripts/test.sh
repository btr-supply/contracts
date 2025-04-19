#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../evm" || exit 1
echo -e "\n>> Running tests\n"
forge test -vvv "$@"
exit_code=$?
echo -e "\n>> $([[ $exit_code -eq 0 ]] && echo '✔️ Success' || echo '⚠️ Failed')\n"
exit $exit_code
