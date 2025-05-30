# Multi-DEX Vault Allocation Methodology

## Overview

The BTR protocol implements a sophisticated risk-based allocation system that **distributes vault TVL across liquidity pools from multiple DEXs** (Uniswap V3, Uniswap V4, PancakeSwap, Thena, etc.) based on composite scoring and exponential weighting. This methodology ensures optimal diversification while maintaining risk-adjusted returns across the multi-DEX ecosystem.

## DEX Pool Composite Scoring (cScore)

### Methodology

Each **DEX liquidity pool** receives a composite score (cScore) that represents its overall quality across multiple dimensions:

1. **Trust Score**: DEX protocol security, audit status, team reputation, decentralization level
2. **Liquidity Score**: Pool TVL depth, trading volume consistency, capital efficiency, slippage characteristics  
3. **Performance Score**: Fee generation efficiency (fee/TVL ratio), impermanent loss/LVR metrics, yield stability

### Geometric Mean Calculation

The composite score uses a geometric mean to ensure balanced evaluation across all risk dimensions:

```solidity
cScore = (trustScore × liquidityScore × performanceScore)^(1/3)
```

**Key Properties:**
- **Zero Tolerance**: Any zero score results in composite zero (eliminates unsafe DEX pools)
- **Balanced Weighting**: No single dimension can dominate the pool score
- **Multiplicative Relationship**: All dimensions must perform reasonably well for high allocation

### Score Range

- **Range**: 0 to 10,000 BPS (0% to 100%)
- **Default**: 5,000 BPS (50%) for new DEX pools
- **Updates**: Manager-controlled via `setPoolCScore()` for each DEX integration

## Weight Allocation Algorithm

### Exponential Weighting

Pool weights are calculated using exponential functions to amplify score differences:

```
weight_i = (cScore_i)^exponent
```

### Weight Model Parameters

```solidity
struct WeightModel {
    uint16 defaultCScore;           // 5000 BPS (50%) - default pool score
    uint16 scoreAmplifierBp;        // 15000 BPS (1.5) - score amplification
    uint16 minMaxBp;                // 2500 BPS (25%) - minimum max weight per pool
    uint16 maxBp;                   // 10000 BPS (100%) - hard weight cap per pool
    uint16 diversificationFactorBp; // 3000 BPS (0.3) - diversification factor
}
```

### Dynamic Max Weight Calculation

Maximum weight per pool decreases with the number of pools to ensure diversification:

```
maxWeight = minMaxBp + e^(-poolCount × diversificationFactorBp)
```

**Example**: With 4 pools and default parameters:
- Base minimum: 25%
- Exponential decay: e^(-4 × 0.3) ≈ 30%
- Effective max weight: ~55% per pool

### Weight Capping Algorithm

The system implements an iterative redistribution algorithm:

1. **Calculate Raw Weights**: Apply exponential function to scores
2. **Identify Excess**: Find pools exceeding maximum weight
3. **Redistribute**: Move excess weight to uncapped pools proportionally
4. **Iterate**: Repeat until convergence (max 10 iterations)

## Allocation Process

### Target Allocation Calculation

For a vault with total TVL in USD:

```solidity
function targetAllocations(
    uint16[] memory cScores,
    uint256 totalAmount,
    uint16 maxWeightBp,
    uint16 scoreAmplifierBp
) returns (uint256[] memory allocations)
```

### Steps:

1. **Score Validation**: Ensure all scores are valid (0-10000 BPS)
2. **Weight Calculation**: Apply exponential weighting with capping
3. **Amount Distribution**: Multiply weights by total amount
4. **Dust Adjustment**: Add remainder to largest allocation

### Example Allocation

**Scenario**: 4 pools with scores [8000, 6000, 4000, 2000] BPS, $1M total

1. **Raw Weights**: [8000^1.5, 6000^1.5, 4000^1.5, 2000^1.5]
2. **Normalized**: [45.3%, 31.2%, 16.0%, 7.5%]
3. **Capped**: Apply 55% max weight (no capping needed)
4. **Final Allocation**: [$453K, $312K, $160K, $75K]

## Risk Management Integration

### Liquidity Requirements

The allocation system integrates with liquidity management:

```solidity
function targetAlmWeightsAndLiquidity(ALMVault storage vault)
    returns (uint256[] memory weights, uint256 targetLiquidityRatioBp)
```

### Dynamic Rebalancing

Allocations adjust automatically based on:
- **Score Updates**: Manager adjustments to pool cScores
- **TVL Changes**: Vault growth/shrinkage affects liquidity ratios
- **Pool Addition/Removal**: Diversification parameters adapt

## Implementation Details

### Gas Optimization

- **Unchecked Math**: Safe overflow assumptions in loops
- **Memory Arrays**: Minimize storage reads
- **Batch Operations**: Process multiple pools efficiently

### Precision Handling

- **WAD Precision**: Internal calculations use 18 decimals
- **BPS Output**: Final weights in basis points (10000 = 100%)
- **Dust Management**: Remainder added to largest allocation

### Validation

- **Score Bounds**: 0 ≤ cScore ≤ 10000 BPS
- **Weight Limits**: Respect maximum weight constraints
- **Sum Verification**: Total weights equal 100%

## Configuration Examples

### Conservative Setup
```solidity
WeightModel({
    defaultCScore: 5000,       // 50% default
    scoreAmplifierBp: 10000,   // 1.0 exponent (linear)
    minMaxBp: 3000,            // 30% min max weight
    maxBp: 5000,               // 50% hard cap
    diversificationFactorBp: 5000 // 0.5 diversification
})
```

### Aggressive Setup
```solidity
WeightModel({
    defaultCScore: 5000,       // 50% default
    scoreAmplifierBp: 20000,   // 2.0 exponent (quadratic)
    minMaxBp: 1000,            // 10% min max weight
    maxBp: 10000,              // 100% hard cap
    diversificationFactorBp: 1000 // 0.1 diversification
})
```

## Monitoring and Analytics

### Key Metrics

- **Effective Diversification**: Herfindahl index of weights
- **Score Distribution**: Range and variance of pool cScores
- **Rebalancing Frequency**: How often allocations change
- **Performance Attribution**: Returns by pool weight

### Risk Indicators

- **Concentration Risk**: Single pool weight > 50%
- **Score Degradation**: Declining cScores over time
- **Liquidity Stress**: Insufficient buffer for redemptions

## Future Enhancements

### Planned Features

1. **Dynamic Scoring**: Automated score updates based on on-chain metrics
2. **Correlation Adjustment**: Account for pool correlation in allocation
3. **Volatility Weighting**: Adjust for pool volatility differences
4. **Time-Weighted Scoring**: Historical performance integration

### Research Areas

- **Machine Learning**: Predictive scoring models
- **Cross-Chain**: Multi-chain allocation optimization
- **MEV Protection**: Front-running resistant rebalancing
- **Liquidity Mining**: Incentive-aware allocation 
