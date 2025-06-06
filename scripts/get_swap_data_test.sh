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
# @title Get Swap Data Test Script - Tests fetching swap data for a specific pool
# @copyright 2025
# @notice Executes a dry run or test call to retrieve swap data, likely for integration testing or debugging swap logic
# @dev Calls `get_swap_data.sh` with test parameters
# @author BTR Team
#

set -euo pipefail

die() { echo "$1"; exit 1; }
ENV_PATH="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)")/evm/.env"

echo "$ENV_PATH"

[ -f "$ENV_PATH" ] || die "Error: .env required for btr-swap"
source "$ENV_PATH"

btr-swap quote \
  --input 56:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c:WBNB:18 \
  --output 56:0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d:USDC:18 \
  --input-amount 1e17 \
  --payer "$DEPLOYER" \
  --aggregators UNIZEN,LIFI,SOCKET,SQUID \
  --display RANK \
  --serialization TABLE --env-file "$ENV_PATH"
