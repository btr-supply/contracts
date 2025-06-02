#!/bin/bash
# SPDX-License-Identifier: MIT
# BTR Build Script - 3-step modular build process for Diamond contracts

set -e
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

# Parse arguments
SIZES_FLAG=""
for arg in "$@"; do
    case $arg in
        --sizes) SIZES_FLAG="--sizes" ;;
        --facets-only) cd "./evm" && forge build --contracts src/facets $SIZES_FLAG && exit 0 ;;
        --deployer-only) cd "./evm" && forge build $SIZES_FLAG && exit 0 ;;
        *) echo "Unknown argument: $arg" && exit 1 ;;
    esac
done

cd "./evm" && rm -rf out

echo "🚀 BTR 3-Step Build Process"

# Step 1: Clean and compile core contracts
echo "⚡ Step 1/3 - Core contracts..."
find . -name "*.gen.sol" -delete 2>/dev/null || true
[ -d scripts ] && mv scripts scripts_hidden
[ -d tests ] && mv tests tests_hidden

if ! forge build $SIZES_FLAG; then
    [ -d scripts_hidden ] && mv scripts_hidden scripts
    [ -d tests_hidden ] && mv tests_hidden tests
    echo "❌ Core compilation failed" && exit 1
fi

# Step 2: Generate deployment files
echo "📝 Step 2/3 - Generating deployment files..."
[ -d scripts_hidden ] && mv scripts_hidden scripts
[ -d tests_hidden ] && mv tests_hidden tests

if ! python3 ../scripts/generate_deployers.py; then
    echo "❌ Generation failed" && exit 1
fi

# Step 3: Final compilation
echo "🔨 Step 3/3 - Final compilation..."
if ! forge build $SIZES_FLAG; then
    echo "❌ Final compilation failed" && exit 1
fi

echo "✅ Build complete - all steps successful"
