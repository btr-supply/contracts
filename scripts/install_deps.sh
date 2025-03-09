#!/bin/bash

# Script to install dependencies without heavy git objects
set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Setting up lightweight dependencies...${NC}"

# Configuration
DEPS_DIR="evm/libraries"
OZ_VERSION="v5.0.1"
OZ_CONTRACTS_REPO="https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/tags/${OZ_VERSION}.zip"
OZ_UPGRADEABLE_REPO="https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/archive/refs/tags/${OZ_VERSION}.zip"

# Create deps directory if it doesn't exist
mkdir -p $DEPS_DIR
cd $DEPS_DIR

# Remove existing dependencies if they exist
rm -rf openzeppelin openzeppelin-upgradeable 2>/dev/null || true

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Download and extract OpenZeppelin contracts
echo -e "${GREEN}Downloading openzeppelin contracts $OZ_VERSION...${NC}"
curl -sL $OZ_CONTRACTS_REPO -o "$TEMP_DIR/oz-contracts.zip"
unzip -q "$TEMP_DIR/oz-contracts.zip" -d "$TEMP_DIR"
mkdir -p openzeppelin
cp -r "$TEMP_DIR/openzeppelin-contracts-${OZ_VERSION#v}/contracts/"* openzeppelin/

# Download and extract OpenZeppelin contracts upgradeable
echo -e "${GREEN}Downloading openzeppelin-upgradeable contracts $OZ_VERSION...${NC}"
curl -sL $OZ_UPGRADEABLE_REPO -o "$TEMP_DIR/oz-contracts-upgradeable.zip"
unzip -q "$TEMP_DIR/oz-contracts-upgradeable.zip" -d "$TEMP_DIR"
mkdir -p openzeppelin-upgradeable
cp -r "$TEMP_DIR/openzeppelin-contracts-upgradeable-${OZ_VERSION#v}/contracts/"* openzeppelin-upgradeable/

# Return to the main directory
cd ../../

# Create or update remappings.txt
echo -e "${GREEN}Creating remappings.txt...${NC}"
cat > remappings.txt << EOL
@openzeppelin/contracts/=evm/libraries/openzeppelin/
@openzeppelin/contracts-upgradeable/=evm/libraries/openzeppelin-upgradeable/
EOL

echo -e "${GREEN}Dependencies installed successfully!${NC}"
du -sh $DEPS_DIR/openzeppelin $DEPS_DIR/openzeppelin-upgradeable
echo -e "${GREEN}Done!${NC}" 
