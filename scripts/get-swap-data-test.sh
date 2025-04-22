#!/bin/bash
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
