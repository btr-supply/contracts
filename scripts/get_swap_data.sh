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
# @title Get Swap Data Script - Fetches swap parameters for a given pool
# @copyright 2025
# @notice Retrieves necessary data (e.g., tick spacing, pool address) for executing a swap on a specific DEX pool, likely using cast or another CLI tool
# @dev Used by ALM or testing scripts to prepare swap transactions
# @author BTR Team
#

set -euo pipefail

die() { echo "$1"; exit 1; }
ENV_PATH="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)")/evm/.env"
LOG_PATH="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)")/logs/btr-swap"

[ -f "$ENV_PATH" ] || die "Error: .env required for btr-swap"
source "$ENV_PATH"

if [ "$#" -lt 3 ]; then
  die "Error: At least 3 arguments required, got $#"
fi

INPUT=${1}; OUTPUT=${2}; INPUT_AMOUNT=${3}; PAYER=${4:-$DEPLOYER}
BEST_COMPACT_CSV=$(btr-swap quote \
  --input "$INPUT" \
  --output "$OUTPUT" \
  --input-amount "$INPUT_AMOUNT" \
  --payer "$PAYER" \
  --aggregators SOCKET,UNIZEN,LIFI \
  --display BEST_COMPACT \
  --serialization CSV \
  --env-file "$ENV_PATH" \
  --log-file "$LOG_PATH" \
  --log-mode JSON) || die "btr-swap failed: $BEST_COMPACT_CSV"

# Remove header line if present before checking comma count
ACTUAL_DATA=$(echo "$BEST_COMPACT_CSV" | sed '1d')

[ $(grep -o ',' <<< "$ACTUAL_DATA" | wc -l) -eq 4 ] || die "Invalid CSV swap output, expected 4 columns, got: $ACTUAL_DATA"

# Output only the actual data line
echo "$ACTUAL_DATA"
