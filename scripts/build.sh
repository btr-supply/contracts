#
# SPDX-License-Identifier: MIT
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
# @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
# @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
# @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
# @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
# @title Build Script - Compiles Solidity contracts using Foundry
# @copyright 2025
# @notice Executes the Foundry build process for the EVM contracts
# @dev Wrapper around `forge build`. Part of the standard build flow
# @author BTR Team
#

set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

# Define paths relative to the script's parent directory (project root)
EVM_DIR="./evm"
GENERATED_DEPLOYER="$EVM_DIR/utils/generated/DiamondDeployer.gen.sol"

via=; sizes=; facets=
for a; do case $a in
  --via-ir) via="--via-ir";;
  --sizes) sizes="--sizes";;
  --facets-only) facets=1;;
esac; done

# EVM Build
echo ">> Building EVM contracts..."
cd "$EVM_DIR"
rm -rf out # Clean previous build artifacts

# Explicitly remove the generated deployer file before any compilation
if [ -f "$GENERATED_DEPLOYER" ]; then
  echo "Removing existing generated deployer: $GENERATED_DEPLOYER"
  rm "$GENERATED_DEPLOYER"
fi

# Step 1: Compile only src contracts (needed for deployer generation)
# Skip if only building facets
[ "${facets}" ] || {
  printf "⏳ 1/3 - Compiling src/facets contracts..."
  # Target only src/facets, skip everything else that might depend on generated code
  if forge build --contracts src/facets --skip scripts --skip tests --skip utils/generated $via $sizes; then
    printf "\r✔️ 1/3 - Src/facets contracts compiled\n"
  else
    printf "\r❌ 1/3 - Src/facets contracts compilation failed\n"; exit 1
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

