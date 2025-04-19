#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

via=; sizes=; facets=
for a; do case $a in
  --via-ir) via="--via-ir";;
  --sizes) sizes="--sizes";;
  --facets-only) facets=1;;
esac; done

# EVM Build
echo ">> Building EVM contracts..."
cd ./evm
rm -rf out # Clean previous build artifacts

# Step 1: Compile only src contracts (needed for deployer generation)
# Skip if only building facets
[ "${facets}" ] || {
  printf "⏳ 1/3 - Compiling src contracts..."
  # Target only src/, no need to skip tests/scripts explicitly
  if forge build --contracts src $via $sizes; then
    printf "\r✔️ 1/3 - Src contracts compiled\n"
  else
    printf "\r❌ 1/3 - Src contracts compilation failed\n"; exit 1
  fi
}

# Exit if only building facets
[ "$facets" ] && {
  printf "\r✔️ facets-only done\n"; exit
}

# Step 2: Generate the deployer utility contract
printf "⏳ 2/3 - Generating deployer..."
if python3 ../scripts/generate_deployer.py out; then
  printf "\r✔️ 2/3 - Deployer generated\n"
else
  printf "\r❌ 2/3 - Deployer generation failed\n"; exit 1
fi

# Step 3: Final compilation including everything (src, tests, scripts)
printf "⏳ 3/3 - Final compilation..."
if forge build $via $sizes; then
  printf "\r✔️ 3/3 - Final build\n"
else
  printf "\r❌ 3/3 - Final build failed\n"; exit 1
fi

# Placeholder for future Solana/Sui builds
# # Solana Build
# echo ">> Building Solana program..."
# cd ../solana
# # Sui Build
# echo ">> Building Sui program..."
# cd ../sui
echo ">> Build complete"

