#!/bin/bash

die() { echo "$1"; exit 1; }
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ENV_PATH="$SCRIPT_DIR/../.env"

[ -f "$ENV_PATH" ] || die "Error: .env not found"
source "$ENV_PATH"

INPUT=${1:?Input missing}
OUTPUT=${2:?Output missing}
INPUT_AMOUNT=${3:?Amount missing}
PAYER=${4:-$DEPLOYER} # from .env

BEST_COMPACT_CSV=$(btr-swap quote \
    --input "$INPUT" \
    --output "$OUTPUT" \
    --input-amount "$INPUT_AMOUNT" \
    --payer "$PAYER" \
    --aggregators SOCKET,UNIZEN \
    --display BEST_COMPACT \
    --serialization CSV \
    --env-file "$ENV_PATH" \
    --silent) || die "btr-swap failed: $BEST_COMPACT_CSV"

[ $(grep -o ',' <<< "$BEST_COMPACT_CSV" | wc -l) -eq 4 ] || die "Invalid CSV: $BEST_COMPACT_CSV"
echo "$BEST_COMPACT_CSV"
