#!/bin/sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Script to fetch dependencies for the project (sh compatible)

EVM_DEPS='https://github.com/OpenZeppelin/openzeppelin-contracts.git,v5.2.0,oz
https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git,v5.2.0,oz-upgradeable
https://github.com/LayerZero-Labs/devtools.git,@layerzerolabs/ua-devtools-evm@5.0.7,lz-devtools
https://github.com/LayerZero-Labs/layerzero-v2,main,lz-v2
https://github.com/foundry-rs/forge-std.git,v1.9.6,forge-std'
SOLANA_DEPS=''
SUI_DEPS=''

TMP=$(mktemp -d)
for chain in evm solana sui; do
  deps=""
  case $chain in
    evm) deps="$EVM_DEPS";;
    solana) deps="$SOLANA_DEPS";;
    sui) deps="$SUI_DEPS";;
  esac
  D=$PROJECT_ROOT/$chain/.deps; mkdir -p "$D"
  n=0; echo "📦 Retrieving $chain deps"
  printf '%s\n' "$deps" | while IFS=, read -r url ver alias; do
    [ -z "$url" ] && continue
    name=$(basename "$url" .git); tgt=$D/${alias:-$name}
    printf "⏳ retrieving %s..." "$name"
    if git -c advice.detachedHead=false clone -q -b "$ver" --depth 1 "$url" "$TMP/$name" > /dev/null 2>&1; then
      rsync -a --delete "$TMP/$name/" "$tgt/" > /dev/null 2>&1
      [ "$chain" = evm ] && find "$tgt" -type f ! -name "*.sol" -delete
      size=$(du -sh "$tgt" | awk '{print $1}')
      printf "\r✔️ %s retrieved (%s)\n" "$name" "$size"; n=$((n+1))
    else
      printf "\r❌ failed to retrieve %s\n" "$name"
    fi
  done
  chain_size=$(du -sh "$D" | awk '{print $1}')
  echo "--- $chain: $n deps ($chain_size)"
done
rm -rf "$TMP"
