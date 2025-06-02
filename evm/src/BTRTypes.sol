// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Types - Custom data structures and types
 * @copyright 2025
 * @notice Defines custom structs, enums, and constants used throughout the BTR protocol
 * @dev Central definition for shared data types
 * @author BTR Team
 */

// --- CONSTANTS ---
// Token type bits for rescue operations
enum TokenType {
    NATIVE, // Native/gas token (eg. ETH, BNB, etc.)
    ERC20, // ERC20 comliant tokens (including ERC777, ERC3643, ERC4626, ERC7540)
    ERC721, // NFTs (ERC721)
    ERC1155 // Multi-token standard (ERC1155)

}

// DEX types for adapter management
enum DEX {
    UNISWAP, // Uniswap V3/V4
    ALGEBRA, // Algebra V3/V4
    RAMSES, // Ramses V3
    CAMELOT, // Camelot V3
    THENA, // Thena V3
    VELO, // Velodrome V3
    AERO, // Aerodrome V3
    PANCAKE, // PancakeSwap V3
    QUICK, // QuickSwap V3
    SUSHI, // SushiSwap V3
    CURVE, // Curve V2
    BALANCER, // Balancer V2
    KYBER, // KyberSwap V3
    TRADER_JOE, // Trader Joe V2
    MERCHANT_MOE, // Merchant Moe V2
    CUSTOM // Custom adapter

}

// Used for blacklisting/whitelisting addresses
enum AddressType {
    NONE, // Not blacklisted
    USER, // User/address blacklisted
    POOL, // Pool blacklisted
    TOKEN, // Token blacklisted
    ROUTER // Router blacklisted

}

enum AccountStatus {
    NONE,
    WHITELISTED,
    BLACKLISTED
}

enum ErrorType {
    CONTRACT,
    FACET,
    ACTION,
    LIBRARY,
    FUNCTION,
    SELECTOR,
    ADDRESS,
    ROLE,
    PROTOCOL,
    ROUTER,
    VAULT,
    TOKEN,
    POOL,
    RANGE,
    TICK,
    DEX,
    ACCESS,
    REENTRANCY,
    MINTER,
    RESCUE,
    ACCEPTANCE,
    ADMIN,
    MANAGER,
    TRANSFER,
    SWAP
}

enum FeeType {
    NONE,
    ENTRY,
    EXIT,
    MANAGEMENT,
    PERFORMANCE,
    FLASH
}

// --- POSITION MANAGEMENT TYPES ---

struct RangeParams {
    bytes32 poolId;
    uint16 weightBp; // % weight of the position total (10000 = 100%)
    uint128 liquidity; // Liquidity of the position
    uint160 lowerPriceX96; // Lower price of the range (in sqrt Q64.96 token0/token1)
    uint160 upperPriceX96; // Upper price of the range (in sqrt Q64.96 token0/token1)
}

struct Range {
    bytes32 id; // Keccak256(abi.encodePacked(poolId, positionId))
    bytes32 positionId; // Id of the underlying position
    bytes32 poolId;
    uint32 vaultId;
    uint16 weightBp; // % weight of the position total (10000 = 100%)
    bool inverted;
    int24 lowerTick;
    int24 upperTick;
    uint128 liquidity;
}

struct MintProceeds {
    uint256 spent0;
    uint256 spent1;
    uint128 shares;
    uint128 protocolFee0;
    uint128 protocolFee1;
}

struct BurnProceeds {
    uint256 recovered0;
    uint256 recovered1;
    uint128 lpFee0;
    uint128 lpFee1;
    uint128 protocolFee0;
    uint128 protocolFee1;
}

struct RebalanceProceeds {
    uint256 spent0;
    uint256 spent1;
    uint128 lpFee0; // from burning
    uint128 lpFee1; // from burning
    uint128 protocolFee0; // from burning
    uint128 protocolFee1; // from burning
}

// Detailed DEX pool information

struct PoolInfo {
    bytes32 id;
    address adapter; // Address of the DEX adapter contract for this pool
    address token0;
    address token1;
    bool inverted;
    uint8 decimals; // LP token decimals
    uint256 weiPerUnit; // Wei per unit of LP token (1e{decimals})
    uint24 tickSize;
    uint32 fee;
    uint16 cScore; // harmonic mean of trust (== sec/track record), liquidity (== scalability), and performance (fee/liquidity)
    bytes32[4] __gap;
}

struct RebalanceParams {
    RangeParams[] ranges;
    address[] swapInputs;
    address[] swapRouters;
    bytes[] swapData;
}

struct RebalancePrep {
    uint256 vwap;
    uint256 totalLiq0;
    uint256 fee0;
    uint256 fee1;
    bool[] inverted;
    int24[] upperTicks;
    int24[] lowerTicks;
    uint256[] lpNeeds;
    uint256[] lpPrices0;
    // Uint256[] lpPrices1;
    address[] swapInputs; // Either of token0 or token1
    uint256[] exactIn; // In input wei
        // Uint256[] estimatedOut; // In output wei
}

// --- DIAMOND STORAGE ---

struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // Position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // Position of facetAddress in facets array
}

// Diamond Storage
struct Diamond {
    address[] facets; // Array of facet addresses
    mapping(bytes4 => bool) supportedInterfaces; // EIP-165 supported interfaces
    bool cutting; // Reentrancy guard
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    bytes32[32] __gap;
}

// --- ACCESS CONTROL TYPES ---

// Role-related structures
struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 adminRole;
}

struct PendingAcceptance {
    bytes32 role;
    address replacing;
    uint64 timestamp;
}

struct AccessControl {
    mapping(address => PendingAcceptance) pendingAcceptance;
    mapping(bytes32 => RoleData) roles;
    uint256 grantDelay; // Delay before a role grant can be accepted
    uint256 acceptanceTtl; // Window of time during which a role grant can be accepted
    bytes32[16] __gap;
}

// --- RESTRICTION STORAGE ---

struct Restrictions {
    bool entered; // Reentrancy guard
    // Restriction bitmask:
    // 0 = restrictSwapCaller
    // 1 = restrictSwapRouter
    // 2 = restrictSwapInput
    // 3 = restrictSwapOutput
    // 4 = restrictBridgeInput
    // 5 = restrictBridgeOutput
    // 6 = restrictBridgeRouter
    // 7 = approveMax
    // 8 = autoRevoke
    uint256 restrictionMask; // Bit flags for various restrictions
    mapping(address => AccountStatus) accountStatus; // Whitelist/blacklist (index 0 is used for protocol level)
    bytes32[16] __gap;
}

// --- ORACLES STORAGE ---

struct Feed {
    address provider;
    bytes32 providerId;
    uint16 twapLookback; // Max 0.75 days == 18 hours (30min is enough for most cases)
    uint16 maxDeviationBp; // In BPS (100 = 1%)
    uint32 ttl; // Max 49710 days
}

struct CoreAddresses {
    address gov; // native chain gov token
    address gas; // native chain gas token
    address usdt; // native/canonical usdt address
    address usdc; // native/canonical usdc address
    address weth; // native/canonical weth address
    address wbtc; // native/canonical wbtc address
    bytes[8] __gap;
}

struct Oracles {
    CoreAddresses addresses;
    mapping(bytes32 => Feed) feeds; // Maps feedId → Feed
    mapping(address => EnumerableSet.Bytes32Set) providerFeeds; // Maps provider → set of feedIds
    uint32 defaultTwapLookback; // Default TWAP lookback
    uint256 defaultMaxDeviation; // Default max deviation
    bytes32[14] __gap; // Adjusted gap due to new fields
}

// --- TREASURY STORAGE ---

struct Fees {
    uint64 updatedAt; // Timestamp of last fee update
    uint16 entry; // Fee charged when entering the vault (minting)
    uint16 exit; // Fee charged when exiting the vault (burning)
    uint16 mgmt; // Ongoing management fee
    uint16 perf; // Fee on profits
    uint16 flash; // Fee for flash loan operations
    bytes32[2] __gap;
}

struct Treasury {
    address collector; // Multisig receiving fees
    mapping(address => Fees) customFees; // Custom fees per user
    // Fees defaultFees; // Protocol default, pending, accrued are stored in vault[0]
    bytes32[32] __gap;
}

// --- VAULT STORAGE ---

struct TimePoints {
    uint64 accruedAt;
    uint64 collectedAt;
    bytes32[2] __gap;
}

// Main vault storage structure
struct ALMVault {
    uint32 id;
    // ERC20 properties
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    uint256 maxSupply; // Maximum supply of vault shares
    mapping(address => uint256) balances; // User balances
    mapping(address => mapping(address => uint256)) allowances; // User allowances
    // Vault positions
    IERC20 token0;
    IERC20 token1;
    uint256 weiPerUnit0;
    uint256 weiPerUnit1;
    bytes32[] ranges;
    // Fee management
    Fees fees;
    mapping(address => uint256) pendingFees; // Pending fees per token
    mapping(address => uint256) accruedFees; // Accrued fees per token
    TimePoints timePoints; // Time points for fees etc
    // Leftover balances (not deployed in LPs)
    mapping(address => uint256) cash; // Unused token balances held by vault, per token
    // Price protection
    uint32 lookback; // TWAP interval in seconds for price validation
    uint256 maxDeviation; // Maximum allowed deviation between current price and TWAP (in basis points)
    // Restriction state
    bool paused; // Pause state for vault operations
    bool mintRestricted; // Uses whitelist if true
    bytes32[16] __gap;
}

// Vault initialization parameters
struct VaultInitParams {
    string name; // Vault name
    string symbol; // Vault symbol
    address token0; // First token in the pair (lower address)
    address token1; // Second token in the pair (higher address)
    uint256 init0; // Initial amount for token0
    uint256 init1; // Initial amount for token1
    uint256 initShares; // Initial share amount for the above deposit (sets initial share price)
}

// --- REGISTRY STORAGE ---

struct Registry {
    uint32 vaultCount; // Number of vaults
    uint32 rangeCount; // Number of ranges
    uint32 poolCount; // Number of pools
    uint64 userCount; // Number of users
    mapping(bytes32 => PoolInfo) poolInfo; // Pool info by poolId
    mapping(uint32 => ALMVault) vaults; // Vaults by id
    mapping(bytes32 => Range) ranges; // Protocol-level storage of ranges by rangeId
    mapping(address => EnumerableSet.Bytes32Set) dexAdapterPools; // Tracks pools for each dex adapter
    bytes32[16] __gap; // Adjusted gap due to new mapping
}

// --- RISK MODEL STORAGE ---

// Risk model storage
struct WeightModel {
    uint16 defaultCScore; // default pool cScore
    uint16 scoreAmplifierBp; // exponent for weight calculation (>1 BPS means low score penalty)
    uint16 minMaxBp; // Minimum maximum weight in basis points (BPS) for dynamic max weight adjustments
    uint16 maxBp; // max single weight in BPS
    uint16 diversificationFactorBp; // High exponent means lower max singgle weight, hence lower diversification
    bytes32[2] __gap;
}

struct LiquidityModel {
    uint16 minRatioBp; // min liquidity ratio in BPS (for dynamic liquidity ratio)
    uint16 tvlExponentBp; // decreases MCR exponentially to TVL increase
    uint16 tvlFactorBp; // decreases MCR linearly to TVL increase
    uint16 lowOffsetBp; // for rebalance triggers (low liquidity)
    uint16 highOffsetBp; // for rebalance triggers (high liquidity)
    bytes32[2] __gap;
}

struct SlippageModel {
    uint16 minSlippageBp; // minimum slippage in BPS (e.g., 10 = 0.1%)
    uint16 maxSlippageBp; // maximum slippage in BPS (e.g., 500 = 5%)
    uint16 amplificationBp; // curve amplification in BPS (0 = log-like, 5000 = linear, 10000 = exponential)
    bytes32[2] __gap;
}

struct RiskModel {
    WeightModel weight;
    LiquidityModel liquidity;
    SlippageModel slippage;
    bytes32[6] __gap; // Reduced gap due to new SlippageModel
}

// --- CORE STORAGE ---

// Core protocol storage
struct CoreStorage {
    // Version control
    uint8 version; // Protocol version
    AccessControl accessControl; // Access control storage
    Restrictions restrictions; // Restriction storage
    RiskModel riskModel; // Risk model storage
    Treasury treasury; // Treasury storage
    Registry registry; // Registry storage (vaults, pools, dexs)
    Oracles oracles; // Oracles storage
    bytes32[64] __gap;
}

// --- RESCUE STORAGE ---

// Request for rescuing stuck tokens
struct RescueRequest {
    uint64 timestamp; // When the rescue was requested
    address receiver; // Address to receive the rescued tokens
    TokenType tokenType; // Type of token (bitmask of TokenType enum)
    address tokenAddress; // Address of the token
    bytes32[] tokenIds; // Token IDs (encoded as bytes32)
}

// Storage for rescue operations
struct Rescue {
    mapping(address => mapping(TokenType => RescueRequest)) rescueRequests;
    uint64 rescueTimelock; // Time that must pass before a rescue can be executed
    uint64 rescueValidity; // Time window during which a rescue request is valid
    bytes32[16] __gap;
}
