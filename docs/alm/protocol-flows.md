# ALM Protocol Flows

This document outlines the administrative and operational flows within the BTR Supply ALM protocol, focusing on vault management, rebalancing operations, and system maintenance performed by admins, managers, and keepers.

## Overview

The BTR protocol operates with three primary operational roles:

- **Admins**: Create vaults, manage protocol settings, handle emergencies
- **Managers**: Configure vault parameters, manage DEX adapters, set weights
- **Keepers**: Execute rebalancing, range management, fee collection

## Vault Creation and Setup

### 1. Vault Creation Flow

```mermaid
graph TD
    A[Admin initiates createVault] --> B[Validate token ordering]
    B --> C[Create ALMVault struct]
    C --> D[Set initial parameters]
    D --> E[Transfer initial tokens if provided]
    E --> F[Mint initial shares if provided]
    F --> G[Emit VaultCreated event]
```

**Function**: `ALMProtectedFacet.createVault()`

**Parameters**:
```solidity
struct VaultInitParams {
    string name;
    string symbol;
    address token0;  // Must be < token1
    address token1;
    uint256 init0;   // Optional initial token0
    uint256 init1;   // Optional initial token1
    uint256 initShares; // Optional initial shares
}
```

**Validation**:
- Token ordering: `token0 < token1`
- Admin role verification
- Non-zero addresses

### 2. DEX Adapter Registration

```mermaid
graph TD
    A[Manager calls setDexAdapter] --> B[Validate adapter address]
    B --> C[Update registry mapping]
    C --> D[Emit DEXAdapterUpdated event]
```

**Function**: `ALMProtectedFacet.setDexAdapter()`

Sets the adapter contract for a specific DEX type (UniV3, CakeV3, Thena).

### 3. Pool Registration

```mermaid
graph TD
    A[Manager calls setPoolInfo] --> B[Validate pool parameters]
    B --> C[Store PoolInfo struct]
    C --> D[Emit PoolUpdated event]
```

**Function**: `ALMProtectedFacet.setPoolInfo()`

**Pool Information**:
```solidity
struct PoolInfo {
    bytes32 id;
    address adapter;
    address pool;
    address token0;
    address token1;
    uint24 fee;
    int24 tickSpacing;
}
```

## Range Management Flows

### 1. Weight Setting

```mermaid
graph TD
    A[Manager calls setWeights] --> B[Validate weights array length]
    B --> C[Check total weight ≤ 100%]
    C --> D[Update range weights]
    D --> E[Store weight configuration]
```

**Function**: `ALMProtectedFacet.setWeights()`

**Weight Rules**:
- Sum of weights must not exceed 10,000 BPS (100%)
- Each weight is stored as basis points (1 BPS = 0.01%)
- Zero weights are allowed (inactive ranges)

### 2. Range Creation Process

```mermaid
graph TD
    A[Define RangeParams] --> B[Calculate range ID]
    B --> C[Store Range struct]
    C --> D[Add to vault ranges array]
    D --> E[Set initial weight]
    E --> F[Ready for liquidity deployment]
```

**Range Parameters**:
```solidity
struct RangeParams {
    bytes32 poolId;
    int24 tickLower;
    int24 tickUpper;
    uint8 weightBp;
}
```

## Rebalancing Operations

### 1. Full Rebalancing Flow

```mermaid
graph TD
    A[Keeper initiates rebalance] --> B[Prepare rebalance data]
    B --> C[Burn all existing ranges]
    C --> D[Collect LP fees]
    D --> E[Accrue protocol fees]
    E --> F[Execute swaps if needed]
    F --> G[Mint new ranges]
    G --> H[Emit VaultRebalanced event]
```

**Function**: `ALMProtectedFacet.rebalance()`

**Detailed Steps**:

1. **Range Burning**: All existing liquidity positions are burned
2. **Fee Collection**: LP fees are collected and protocol fees calculated
3. **Swap Execution**: Required token swaps to achieve target ratios
4. **Range Minting**: New liquidity positions created according to strategy

### 2. Incremental Range Management

#### Mint Ranges Only
```mermaid
graph TD
    A[Keeper calls mintRanges] --> B[Use existing cash balances]
    B --> C[Deploy liquidity to specified ranges]
    C --> D[Update range liquidity amounts]
```

**Function**: `ALMProtectedFacet.mintRanges()`

#### Burn Ranges Only
```mermaid
graph TD
    A[Keeper calls burnRanges] --> B[Burn all vault ranges]
    B --> C[Collect tokens and fees]
    C --> D[Update cash balances]
    D --> E[Optionally remove from vault array]
```

**Function**: `ALMProtectedFacet.burnRanges()`

#### Remint Existing Ranges
```mermaid
graph TD
    A[Keeper calls remintRanges] --> B[Use existing range configurations]
    B --> C[Deploy available cash]
    C --> D[Maintain current weights]
```

**Function**: `ALMProtectedFacet.remintRanges()`

## Fee Management Flows

### 1. Fee Accrual Process

```mermaid
graph TD
    A[LP fees collected from DEX] --> B[Calculate performance fees]
    B --> C[Calculate management fees]
    C --> D[Update vault fee accounting]
    D --> E[Update accrual timestamp]
```

**Fee Types**:
- **Performance Fees**: Percentage of LP fee revenue
- **Management Fees**: Time-based fees on vault TVL
- **Entry/Exit Fees**: Applied to user operations

### 2. Fee Collection Flow

```mermaid
graph TD
    A[Treasury calls collectAlmFees] --> B[Calculate collectable amounts]
    B --> C[Transfer fees to treasury]
    C --> D[Reset vault fee accounting]
    D --> E[Emit ALMFeesCollected event]
```

**Function**: `TreasuryFacet.collectAlmFees()`

**Access Control**: Only treasury role can collect fees

## Vault State Management

### 1. Pause/Unpause Operations

```mermaid
graph TD
    A[Manager initiates pause] --> B[Set vault.paused = true]
    B --> C[Block user operations]
    C --> D[Emit Paused event]
    
    E[Manager initiates unpause] --> F[Validate vault is paused]
    F --> G[Set vault.paused = false]
    G --> H[Resume user operations]
    H --> I[Emit Unpaused event]
```

**Functions**:
- `ALMProtectedFacet.pauseAlmVault()`
- `ALMProtectedFacet.unpauseAlmVault()`

### 2. Mint Restriction Management

```mermaid
graph TD
    A[Manager calls restrictMint] --> B[Set vault.mintRestricted]
    B --> C[Update access permissions]
    C --> D[Emit restriction event]
```

**Function**: `ALMProtectedFacet.restrictMint()`

**Effect**: When restricted, only unrestricted minters can deposit

## Operational Monitoring

### 1. Rebalance Preparation

```mermaid
graph TD
    A[Call prepareRebalance] --> B[Simulate range burning]
    B --> C[Calculate current liquidity]
    C --> D[Determine required swaps]
    D --> E[Return RebalancePrep data]
```

**Function**: `ALMProtectedFacet.prepareRebalance()`

**Returns**:
```solidity
struct RebalancePrep {
    uint256 vwap;           // Current VWAP
    uint256 totalLiq0;      // Total liquidity in token0 terms
    uint256 fee0;           // Protocol fees token0
    uint256 fee1;           // Protocol fees token1
    bool[] inverted;        // Range inversion flags
    int24[] lowerTicks;     // Lower tick bounds
    int24[] upperTicks;     // Upper tick bounds
    uint256[] lpNeeds;      // Liquidity needs per range
    uint256[] lpPrices0;    // LP prices in token0
}
```

### 2. Range Burn Preview

```mermaid
graph TD
    A[Call previewBurnRanges] --> B[Simulate burning all ranges]
    B --> C[Calculate recoverable tokens]
    C --> D[Calculate LP fees]
    D --> E[Return preview data]
```

**Function**: `ALMProtectedFacet.previewBurnRanges()`

## Emergency Procedures

### 1. Protocol-Level Pause

```mermaid
graph TD
    A[Emergency detected] --> B[Admin calls pause]
    B --> C[Pause vault ID 0 (protocol)]
    C --> D[All operations halted]
    D --> E[Investigate and resolve]
    E --> F[Admin calls unpause]
    F --> G[Operations resume]
```

### 2. Asset Recovery

```mermaid
graph TD
    A[Stuck assets detected] --> B[Admin requests rescue]
    B --> C[Wait for timelock period]
    C --> D[Execute rescue operation]
    D --> E[Transfer assets to receiver]
```

**Process**: Uses timelock mechanism for security

## Integration with External Systems

### 1. Keeper Network Integration

```mermaid
graph TD
    A[Keeper monitors conditions] --> B[Detect rebalance trigger]
    B --> C[Prepare rebalance parameters]
    C --> D[Submit rebalance transaction]
    D --> E[Validate execution]
```

**Trigger Conditions**:
- Liquidity ratio thresholds
- Time-based rebalancing
- Market condition changes
- Manual triggers

### 2. Oracle Integration

```mermaid
graph TD
    A[Price feeds update] --> B[VWAP calculation]
    B --> C[Range optimization]
    C --> D[Rebalance decision]
```

**Price Sources**:
- DEX pool prices
- External oracle feeds
- TWAP calculations

## Access Control Matrix

| Operation | Admin | Manager | Keeper | Treasury |
|-----------|-------|---------|--------|----------|
| Create Vault | ✓ | ✗ | ✗ | ✗ |
| Set DEX Adapter | ✗ | ✓ | ✗ | ✗ |
| Set Pool Info | ✗ | ✓ | ✗ | ✗ |
| Set Weights | ✗ | ✓ | ✗ | ✗ |
| Zero Weights | ✗ | ✓ | ✗ | ✗ |
| Pause Vault | ✗ | ✓ | ✗ | ✗ |
| Restrict Mint | ✗ | ✓ | ✗ | ✗ |
| Rebalance | ✗ | ✗ | ✓ | ✗ |
| Mint Ranges | ✗ | ✗ | ✓ | ✗ |
| Burn Ranges | ✗ | ✗ | ✓ | ✗ |
| Remint Ranges | ✗ | ✗ | ✓ | ✗ |
| Collect Fees | ✗ | ✗ | ✗ | ✓ |

## Performance Monitoring

### Key Metrics

1. **Rebalancing Frequency**: How often vaults rebalance
2. **Gas Efficiency**: Cost per operation
3. **Fee Generation**: Protocol revenue
4. **Liquidity Utilization**: Active vs. idle capital
5. **Slippage Impact**: Cost of rebalancing operations

### Operational Dashboards

- **Vault Performance**: TVL, APY, fee generation
- **Range Analytics**: Liquidity distribution, efficiency
- **Keeper Operations**: Rebalancing frequency, gas costs
- **Fee Analytics**: Revenue breakdown, collection rates

This comprehensive protocol flow documentation ensures proper understanding and execution of all administrative and operational aspects of the BTR Supply ALM system.
