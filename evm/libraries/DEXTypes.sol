// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title DEX Types Library
/// @notice Defines constants for different DEX types to be used across the protocol
/// @dev Uses keccak256 hashes of DEX names for unique identification
library DEXTypes {
    // Core DEXes
    bytes32 public constant UNISWAP = keccak256("uniswap");
    bytes32 public constant PANCAKESWAP = keccak256("pancakeswap");
    bytes32 public constant VELODROME = keccak256("velodrome");
    bytes32 public constant AERODROME = keccak256("aerodrome");
    bytes32 public constant CAMELOT = keccak256("camelot");
    bytes32 public constant THENA = keccak256("thena");
    bytes32 public constant MAVERICK = keccak256("maverick");
    bytes32 public constant JOE = keccak256("joe");
    bytes32 public constant MERCHANT_MOE = keccak256("merchant_moe");
    bytes32 public constant SUSHISWAP = keccak256("sushiswap");
    bytes32 public constant QUICKSWAP = keccak256("quickswap");
    bytes32 public constant SHADOW = keccak256("shadow");
    bytes32 public constant KODIAK = keccak256("kodiak");
    bytes32 public constant SWAPX = keccak256("swapx");
    bytes32 public constant LYNEX = keccak256("lynex");
    bytes32 public constant ALIEN_BASE = keccak256("alien_base");
    bytes32 public constant AGNI = keccak256("agni");
    bytes32 public constant RESERVOIR = keccak256("reservoir");
    bytes32 public constant THRUSTER = keccak256("thruster");
    bytes32 public constant RAMSES = keccak256("ramses");
    bytes32 public constant PHARAOH = keccak256("pharaoh");
    bytes32 public constant CLEOPATRA = keccak256("cleopatra");
    bytes32 public constant NILE = keccak256("nile");
    bytes32 public constant NURI = keccak256("nuri");
    bytes32 public constant BULLA = keccak256("bulla");
    bytes32 public constant DRAGONSWAP = keccak256("dragonswap");
    bytes32 public constant IZISWAP = keccak256("iziswap");
    bytes32 public constant SYNCSWAP = keccak256("syncswap");
    bytes32 public constant STORY_HUNT = keccak256("story_hunt");
    bytes32 public constant SPARK_DEX = keccak256("spark_dex");
    bytes32 public constant PIPERX = keccak256("piperx");
    bytes32 public constant RETRO = keccak256("retro");
    bytes32 public constant HYPERSWAP = keccak256("hyperswap");
    bytes32 public constant BISWAP = keccak256("biswap");
    bytes32 public constant OCELEX = keccak256("ocelex");
    bytes32 public constant FENIX = keccak256("fenix");
    bytes32 public constant KOI = keccak256("koi");
    bytes32 public constant HERCULES = keccak256("hercules");
    bytes32 public constant SWAPR = keccak256("swapr");
    bytes32 public constant EQUALIZER = keccak256("equalizer");
    bytes32 public constant WAGMI = keccak256("wagmi");
    bytes32 public constant KIM = keccak256("kim");
    bytes32 public constant STELLASWAP = keccak256("stellaswap");

    /// @notice Check if a DEX type is valid
    /// @param dexType The DEX type to check
    /// @return True if the DEX type is supported
    function isValidDEX(bytes32 dexType) internal pure returns (bool) {
        // This function can be extended as more DEXes are added
        return (
            dexType == UNISWAP ||
            dexType == PANCAKESWAP ||
            dexType == VELODROME ||
            dexType == AERODROME ||
            dexType == CAMELOT ||
            dexType == THENA ||
            dexType == MAVERICK ||
            dexType == JOE ||
            dexType == MERCHANT_MOE ||
            dexType == SUSHISWAP ||
            dexType == QUICKSWAP ||
            dexType == SHADOW ||
            dexType == KODIAK ||
            dexType == SWAPX ||
            dexType == LYNEX ||
            dexType == ALIEN_BASE ||
            dexType == AGNI ||
            dexType == RESERVOIR ||
            dexType == THRUSTER ||
            dexType == RAMSES ||
            dexType == PHARAOH ||
            dexType == CLEOPATRA ||
            dexType == NILE ||
            dexType == NURI ||
            dexType == BULLA ||
            dexType == DRAGONSWAP ||
            dexType == IZISWAP ||
            dexType == SYNCSWAP ||
            dexType == STORY_HUNT ||
            dexType == SPARK_DEX ||
            dexType == PIPERX ||
            dexType == RETRO ||
            dexType == HYPERSWAP ||
            dexType == BISWAP ||
            dexType == OCELEX ||
            dexType == FENIX ||
            dexType == KOI ||
            dexType == HERCULES ||
            dexType == SWAPR ||
            dexType == EQUALIZER ||
            dexType == WAGMI ||
            dexType == KIM ||
            dexType == STELLASWAP
        );
    }
} 