# TVL Accounting and Metrics

## Overview

The BTR Supply protocol implements comprehensive TVL (Total Value Locked) accounting to accurately track vault performance, enable fee calculations, and provide transparency to users and administrators. This document outlines the accounting methodology, calculation formulas, and implementation details.

## TVL Components

### Vault Balance Structure

Each ALM vault tracks multiple balance components:

```solidity
struct ALMVault {
    mapping(address => uint256) cash;    // Token cash balances
    bytes32[] ranges;                    // Active liquidity ranges
    uint256 totalSupply;                 // Outstanding shares
    uint256 weiPerUnit0;                 // Token0 decimals scaling
    uint256 weiPerUnit1;                 // Token1 decimals scaling
    // ... other fields
}
```

### Balance Categories

1. **Cash Balances**: Idle tokens held in the vault
2. **LP Balances**: Tokens deployed in liquidity positions
3. **Total Balances**: Sum of cash and LP balances

## TVL Calculation Methods

### 1. Total Vault Balances

```solidity
function totalBalances(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (uint256 balance0, uint256 balance1) {
    
    (uint256 lp0, uint256 lp1) = lpBalances(_vault, _reg);
    balance0 = _vault.cash0() + lp0;
    balance1 = _vault.cash1() + lp1;
}
```

**Components**:
- **Cash**: `_vault.cash[token0]` + `_vault.cash[token1]`
- **LP Positions**: Sum of all active range balances
- **Total**: Cash + LP balances

### 2. LP Position Balances

```solidity
function lpBalances(ALMVault storage _vault, Registry storage _reg)
    internal view returns (uint256 total0, uint256 total1) {
    
    uint256 length = _vault.ranges.length;
    for (uint256 i = 0; i < length; i++) {
        bytes32 rid = _vault.ranges[i];
        (uint256 amount0, uint256 amount1) = rangeLpBalances(rid, _reg);
        total0 += amount0;
        total1 += amount1;
    }
}
```

Each range contributes its pro-rata share of liquidity to the total.

### 3. USD Value Calculation

```solidity
function almTvlUsd(ALMVault storage _vault) 
    internal view returns (
        uint256 balance0, 
        uint256 balance1, 
        uint256 balanceUsd0, 
        uint256 balanceUsd1
    ) {
    
    (balance0, balance1) = _vault.totalBalances();
    balanceUsd0 = _vault.token0.toUsd(balance0);
    balanceUsd1 = _vault.token1.toUsd(balance1);
}
```

**Total USD TVL**: `balanceUsd0 + balanceUsd1`

## Price Conversion Methods

### 1. Oracle-Based USD Conversion

Uses integrated oracle feeds to convert token amounts to USD values:

```solidity
function toUsd(address token, uint256 amount) internal view returns (uint256) {
    uint256 price = getOraclePrice(token);  // Price in USD with 8 decimals
    uint256 decimals = IERC20Metadata(token).decimals();
    return amount.mulDivDown(price, 10**decimals * 1e8);
}
```

### 2. ETH-Based Valuation

Alternative valuation in ETH terms:

```solidity
function almTvlEth(ALMVault storage _vault)
    internal view returns (
        uint256 balance0,
        uint256 balance1, 
        uint256 balanceEth0,
        uint256 balanceEth1
    ) {
    
    (balance0, balance1) = _vault.totalBalances();
    balanceEth0 = _vault.token0.toEth(balance0);
    balanceEth1 = _vault.token1.toEth(balance1);
}
```

## Range-Level Accounting

### Range Balance Calculation

```solidity
function rangeLpBalances(bytes32 _rid, Registry storage _reg)
    internal view returns (uint256 amount0, uint256 amount1) {
    
    Range memory range = _reg.ranges[_rid];
    address adapter = poolInfo(range.poolId, _reg).adapter;
    
    return IDEX(adapter).positionAmounts(_rid);
}
```

### Range Liquidity Tracking

Each range maintains:
- **Liquidity**: Current liquidity amount (uint128)
- **Tick Bounds**: Lower and upper tick boundaries
- **Weight**: Allocation percentage in basis points
- **Pool ID**: Reference to the underlying DEX pool

## Share Value Calculations

### 1. Shares to Token Amounts

```solidity
function sharesToAmounts(
    ALMVault storage _vault,
    Registry storage _reg,
    uint256 _shares,
    FeeType _feeType,
    address _user
) internal returns (uint256 net0, uint256 net1, uint256 fee0, uint256 fee1) {
    
    if (_shares == 0) return (0, 0, 0, 0);
    
    (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
    if (_vault.totalSupply == 0 || balance0 + balance1 == 0) {
        revert Errors.NotInitialized();
    }
    
    uint256 gross0 = balance0.mulDivUp(_shares, _vault.totalSupply);
    uint256 gross1 = balance1.mulDivUp(_shares, _vault.totalSupply);
    
    // Apply fees if specified
    if (_feeType != FeeType.NONE) {
        (net0, net1, fee0, fee1) = applyActionFees(gross0, gross1, fee, reverseFee);
    } else {
        (net0, net1) = (gross0, gross1);
    }
}
```

### 2. Token Amounts to Shares

```solidity
function amountsToShares(
    ALMVault storage _vault,
    Registry storage _reg,
    uint256 _amount0,
    uint256 _amount1,
    FeeType _feeType,
    address _user
) internal returns (uint256 shares, uint256 fee0, uint256 fee1, int256 rd0) {
    
    (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
    
    if (_vault.totalSupply == 0) {
        // Initial deposit calculation
        shares = Math.sqrt(_amount0 * _amount1);
    } else {
        // Pro-rata share calculation
        uint256 supply = _vault.totalSupply;
        uint256 shares0 = _amount0.mulDivDown(supply, balance0);
        uint256 shares1 = _amount1.mulDivDown(supply, balance1);
        shares = Math.min(shares0, shares1);
    }
    
    // Calculate ratio difference for fee adjustment
    rd0 = calculateRatioDifference(_vault, _amount0, _amount1);
    
    // Apply fees
    if (_feeType != FeeType.NONE) {
        (shares, fee0, fee1) = applyEntryFees(shares, _amount0, _amount1, rd0);
    }
}
```

## Fee Accounting

### 1. Performance Fee Calculation

```solidity
function calculatePerformanceFee(
    ALMVault storage _vault,
    uint256 _lpFee0,
    uint256 _lpFee1
) internal view returns (uint256 perfFee0, uint256 perfFee1) {
    
    Fees memory fees = almVaultFees(_vault);
    perfFee0 = _lpFee0.mulDivDown(fees.perf, BPS);
    perfFee1 = _lpFee1.mulDivDown(fees.perf, BPS);
}
```

### 2. Management Fee Calculation

```solidity
function calculateManagementFee(
    ALMVault storage _vault,
    Registry storage _reg
) internal view returns (uint256 mgmtFee0, uint256 mgmtFee1) {
    
    uint256 timeDelta = block.timestamp - _vault.timePoints.accruedAt;
    (uint256 tvl0, uint256 tvl1) = totalBalances(_vault, _reg);
    
    Fees memory fees = almVaultFees(_vault);
    uint256 annualRate = fees.mgmt;
    
    mgmtFee0 = tvl0.mulDivDown(annualRate * timeDelta, BPS * 365 days);
    mgmtFee1 = tvl1.mulDivDown(annualRate * timeDelta, BPS * 365 days);
}
```

### 3. Fee Accrual Process

```solidity
function accrueAlmFees(
    ALMVault storage _vault,
    Registry storage _reg,
    uint256 _lpFee0,
    uint256 _lpFee1
) internal returns (uint256 perfFee0, uint256 perfFee1, uint256 mgmtFee0, uint256 mgmtFee1) {
    
    // Calculate performance fees
    (perfFee0, perfFee1) = calculatePerformanceFee(_vault, _lpFee0, _lpFee1);
    
    // Calculate management fees
    (mgmtFee0, mgmtFee1) = calculateManagementFee(_vault, _reg);
    
    // Update vault fee tracking
    _vault.pendingFees0 += perfFee0 + mgmtFee0;
    _vault.pendingFees1 += perfFee1 + mgmtFee1;
    _vault.timePoints.accruedAt = uint64(block.timestamp);
    
    emit Events.ALMFeesAccrued(_vault.id, address(_vault.token0), address(_vault.token1), 
                               perfFee0, perfFee1, mgmtFee0, mgmtFee1);
}
```

## VWAP Calculation

### Volume-Weighted Average Price

```solidity
function vwap(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (uint256) {
    
    uint256 totalValue0 = 0;
    uint256 totalLiquidity = 0;
    uint256 length = _vault.ranges.length;
    
    for (uint256 i = 0; i < length; i++) {
        bytes32 rid = _vault.ranges[i];
        Range memory range = _reg.ranges[rid];
        
        if (range.liquidity > 0) {
            uint256 price = rangeMidPrice(rid, _reg);
            uint256 weight = range.weightBp;
            
            totalValue0 += price.mulDivDown(weight, BPS);
            totalLiquidity += weight;
        }
    }
    
    return totalLiquidity > 0 ? totalValue0.mulDivDown(BPS, totalLiquidity) : 0;
}
```

## Ratio Tracking

### 1. Current Vault Ratio

```solidity
function ratio0(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (uint256) {
    
    (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
    uint256 vwapPrice = vwap(_vault, _reg);
    
    if (vwapPrice == 0) return 0;
    
    uint256 totalValue0 = balance0 + balance1.mulDivDown(vwapPrice, _vault.weiPerUnit0);
    return totalValue0 > 0 ? balance0.mulDivDown(BPS, totalValue0) : 0;
}
```

### 2. Target Ratio Calculation

```solidity
function targetRatio0(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (uint256) {
    
    uint256 totalWeight = 0;
    uint256 weightedRatio = 0;
    uint256 length = _vault.ranges.length;
    
    for (uint256 i = 0; i < length; i++) {
        bytes32 rid = _vault.ranges[i];
        Range memory range = _reg.ranges[rid];
        
        uint256 rangeRatio = rangeLiquidityRatio0(rid, _reg);
        uint256 weight = range.weightBp;
        
        weightedRatio += rangeRatio.mulDivDown(weight, BPS);
        totalWeight += weight;
    }
    
    return totalWeight > 0 ? weightedRatio.mulDivDown(BPS, totalWeight) : 0;
}
```

## Performance Metrics

### 1. APY Calculation

```solidity
function calculateAPY(
    ALMVault storage _vault,
    Registry storage _reg,
    uint256 _timePeriod
) internal view returns (uint256 apy) {
    
    (uint256 currentTvl0, uint256 currentTvl1) = totalBalances(_vault, _reg);
    uint256 currentTvl = currentTvl0 + currentTvl1.mulDivDown(vwap(_vault, _reg), _vault.weiPerUnit0);
    
    uint256 historicalTvl = getHistoricalTvl(_vault, block.timestamp - _timePeriod);
    uint256 totalFees = _vault.accruedFees0 + _vault.accruedFees1.mulDivDown(vwap(_vault, _reg), _vault.weiPerUnit0);
    
    if (historicalTvl > 0 && _timePeriod > 0) {
        uint256 periodReturn = totalFees.mulDivDown(BPS, historicalTvl);
        apy = periodReturn.mulDivDown(365 days, _timePeriod);
    }
}
```

### 2. Sharpe Ratio

```solidity
function calculateSharpeRatio(
    ALMVault storage _vault,
    uint256 _riskFreeRate,
    uint256 _timePeriod
) internal view returns (uint256 sharpe) {
    
    uint256 vaultReturn = calculateAPY(_vault, _reg, _timePeriod);
    uint256 excessReturn = vaultReturn > _riskFreeRate ? vaultReturn - _riskFreeRate : 0;
    uint256 volatility = calculateVolatility(_vault, _timePeriod);
    
    return volatility > 0 ? excessReturn.mulDivDown(BPS, volatility) : 0;
}
```

## Accounting Integrity

### 1. Balance Reconciliation

```solidity
function reconcileBalances(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (bool isReconciled) {
    
    // Check that reported balances match actual token balances
    uint256 reportedCash0 = _vault.cash0();
    uint256 reportedCash1 = _vault.cash1();
    
    uint256 actualCash0 = _vault.token0.balanceOf(address(this));
    uint256 actualCash1 = _vault.token1.balanceOf(address(this));
    
    (uint256 lpBalance0, uint256 lpBalance1) = lpBalances(_vault, _reg);
    
    isReconciled = (reportedCash0 + lpBalance0 == actualCash0 + lpBalance0) &&
                   (reportedCash1 + lpBalance1 == actualCash1 + lpBalance1);
}
```

### 2. Share Supply Validation

```solidity
function validateShareSupply(ALMVault storage _vault) 
    internal view returns (bool isValid) {
    
    uint256 calculatedSupply = 0;
    
    // Sum all user balances
    // This would require iterating through all holders in a real implementation
    // or maintaining a separate tracking mechanism
    
    isValid = calculatedSupply == _vault.totalSupply;
}
```

## Event Tracking

### Important Events for Accounting

```solidity
// Vault balance changes
event SharesMinted(address indexed payer, address indexed receiver, 
                  uint256 mintedShares, uint256 amount0, uint256 amount1, 
                  uint256 fee0, uint256 fee1);

event SharesBurnt(address indexed payer, address indexed receiver,
                 uint256 burntShares, uint256 amount0, uint256 amount1,
                 uint256 fee0, uint256 fee1);

// Range operations
event RangeMinted(bytes32 indexed rid, uint256 liquidity, 
                 uint256 amount0, uint256 amount1);

event RangeBurnt(bytes32 indexed rid, uint256 liquidity,
                uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1);

// Fee accounting
event ALMFeesAccrued(uint32 indexed vid, address indexed token0, address indexed token1,
                    uint256 perfFee0, uint256 perfFee1, uint256 mgmtFee0, uint256 mgmtFee1);

event ALMFeesCollected(uint32 indexed vid, address indexed token0, address indexed token1,
                      uint256 fee0, uint256 fee1, address by);
```

## Data Export and Analytics

### 1. Vault Snapshot

```solidity
struct VaultSnapshot {
    uint32 vid;
    uint256 timestamp;
    uint256 totalSupply;
    uint256 balance0;
    uint256 balance1;
    uint256 cash0;
    uint256 cash1;
    uint256 lpBalance0;
    uint256 lpBalance1;
    uint256 vwap;
    uint256 ratio0;
    uint256 targetRatio0;
    uint256 pendingFees0;
    uint256 pendingFees1;
}
```

### 2. Range Analytics

```solidity
struct RangeSnapshot {
    bytes32 rid;
    bytes32 poolId;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    uint256 amount0;
    uint256 amount1;
    uint256 weightBp;
    uint256 utilization;
}
```

This comprehensive TVL accounting system ensures accurate tracking of all vault assets, proper fee calculations, and transparent reporting for users and administrators.
