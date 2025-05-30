# Weight Model and DEX Pool Allocation System

## Theoretical Foundations

### Portfolio Theory Connections for Liquidity Pool Optimization

The BTR allocation system optimizes **TVL allocation across liquidity pools from multiple DEXs** (Uniswap V3, Uniswap V4, PancakeSwap, etc.), not traditional financial portfolios. However, we strategically borrow concepts from modern portfolio theory because:

- **Vault as Portfolio Analogy**: Each ALM vault functions like a portfolio where the "assets" are liquidity positions across different DEX pools
- **Pool Diversification**: Similar to asset diversification in traditional finance, we diversify across multiple DEX pools to optimize risk-adjusted returns
- **Risk-Return Optimization**: Pool selection and weighting follows similar mathematical principles as portfolio optimization

This approach applies established financial theory to the novel challenge of **multi-DEX liquidity management**.

#### **Geometric Mean Scoring Theory**
The composite scoring methodology draws from geometric mean optimization theory, which has been shown to maximize long-term growth rates under uncertainty. The geometric mean composite score ensures:

- **Balanced Risk Assessment**: No single risk dimension can dominate pool allocation decisions
- **Zero-Sensitivity Property**: Complete failure in any dimension (score = 0) eliminates the pool from consideration
- **Multiplicative Risk Model**: Risks compound rather than add linearly, consistent with financial theory

This approach aligns with the **Kelly Criterion** principle of maximizing logarithmic utility, where the geometric mean of returns optimizes long-term growth across DEX pools.

#### **Exponential Weighting and Power Utility**
The `scoreAmplifierBp` parameter implements a form of **power utility function** common in portfolio optimization:

```
U(w) = w^α where α = scoreAmplifierBp
```

This creates varying levels of risk aversion for pool allocation:
- α < 1.0: Risk-averse (flattened distribution across pools)
- α = 1.0: Risk-neutral (linear scaling)  
- α > 1.0: Risk-seeking (concentrated allocation to high-scoring pools)

#### **Dynamic Diversification and Factor Models**
The exponential decay in maximum weights resembles **factor-based allocation** strategies:

```
maxWeight = minMaxBp + e^(-n × diversificationFactor)
```

This implements:
- **Diminishing Marginal Utility**: Additional pool positions provide decreasing diversification benefits
- **Scale-Dependent Risk Management**: Larger pool opportunity sets require more diversification
- **Concentration Limits**: Prevents over-allocation to single DEX pools

#### **Black-Litterman Model Similarities**
While not requiring explicit investor views, the system shares characteristics with the **Black-Litterman model**:

- **Prior Information**: Default cScores serve as equilibrium "prior" beliefs about pool quality
- **View Integration**: Individual pool scores override defaults when available
- **Uncertainty Handling**: Lower scores reduce allocation confidence, similar to uncertain views
- **Optimization Constraints**: Weight caps prevent extreme allocations to single pools

#### **Risk Parity Principles**
The iterative weight capping and redistribution mechanism implements concepts from **Risk Parity** allocation:

- **Equal Risk Contribution**: Prevents single pools from dominating vault risk
- **Dynamic Rebalancing**: Excess weight redistribution maintains balanced exposure across DEXs
- **Constraint Optimization**: Iterative process finds feasible allocations under constraints

### Academic References

- **Kelly, J.L.** (1956). "A New Interpretation of Information Rate" - Geometric mean optimization
- **Black, F. & Litterman, R.** (1992). "Global Portfolio Optimization" - Bayesian asset allocation
- **Qian, E.** (2005). "Risk Parity Portfolios" - Equal risk contribution strategies
- **Maillard, S. et al.** (2010). "The Properties of Equally Weighted Risk Contribution Portfolios" - ERC optimization

## Overview

The BTR protocol implements a sophisticated weight-based allocation system that **distributes vault TVL across liquidity pools from multiple DEXs** based on quantitative pool quality assessment. The system uses composite scoring, exponential weighting, and capping mechanisms to optimize risk-adjusted returns across the multi-DEX ecosystem.

## Pool Composite Scoring (cScore)

### Core Scoring Methodology

Each **DEX liquidity pool** receives individual scores across three critical dimensions, which are combined into a single composite score (`cScore`):

- **Trust Score** (0-10000): DEX protocol security, audit history, team reputation, decentralization
- **Liquidity Score** (0-10000): Pool TVL depth, trading volume, capital efficiency, slippage characteristics  
- **Performance Score** (0-10000): Fee generation efficiency, impermanent loss profile, LP profitability

### Composite Score Calculation

The `cScore` uses a **geometric mean** (not harmonic mean) of the individual scores:

```
cScore = (trustScore × liquidityScore × performanceScore)^(1/3)
```

**Mathematical Properties:**
- **Zero Sensitivity**: Any individual score of 0 results in cScore = 0 (eliminates unsafe pools)
- **Balanced Requirement**: Poor performance in any dimension significantly reduces the composite score
- **Scale Preservation**: Maintains the 0-10000 range while encouraging balanced pool profiles

```solidity
function cScore(uint16[] memory _scores) internal pure returns (uint16) {
    uint256 n = _scores.length;
    if (n == 0) return 0;
    if (n == 1) return _scores[0];
    
    // Calculate geometric mean: (s1 × s2 × ... × sn)^(1/n)
    uint256 prodWad = M.WAD;
    for (uint256 i; i < n; i++) {
        if (_scores[i] == 0) return 0; // Zero score makes composite zero
        prodWad = prodWad.mulWad(uint256(_scores[i]).toWad());
    }
    
    // nth root using logarithmic functions
    int256 logProd = M.lnWad(int256(prodWad));
    int256 geomWad = M.expWad(logProd / int256(n));
    
    return uint16(uint256(geomWad).mulDivDown(MAX_SCORE, M.WAD));
}
```

## Weight Model Parameters

### Core Structure

```solidity
struct WeightModel {
    uint16 defaultCScore;           // 5000 BPS (50%) - default pool cScore
    uint16 scoreAmplifierBp;        // 15000 BPS (1.5) - score exponentiation factor
    uint16 minMaxBp;                // 2500 BPS (25%) - minimum maximum weight per pool
    uint16 maxBp;                   // 10000 BPS (100%) - absolute maximum weight per pool
    uint16 diversificationFactorBp; // 3000 BPS (0.3) - exponential decay factor for max weight
}
```

### Parameter Validation

- **scoreAmplifierBp**: 7500-25000 BPS (0.75-2.5x) - prevents extreme weight concentration
- **maxBp**: 1000-10000 BPS (10%-100%) - hard cap on individual pool allocation
- **minMaxBp**: ≤maxBp - minimum floor for dynamic max weight calculation
- **diversificationFactorBp**: 500-20000 BPS (0.05-2.0) - controls diversification vs. concentration

## Dynamic Maximum Weight Calculation

### Component-Based Maximum Weight

The maximum weight per pool decreases exponentially as the number of pools increases:

```
maxWeight = minMaxBp + e^(-n × diversificationFactorBp)
```

Where:
- `n` = number of pools/components in the vault
- `diversificationFactorBp` = exponential decay rate

**Mathematical Properties:**
- **Diversification Incentive**: More pools → lower individual max weights
- **Quality Concentration**: Few high-quality pools can receive larger allocations
- **Asymptotic Floor**: Approaches `minMaxBp` as n → ∞

```solidity
function componentMaxWeightBp(
    uint256 _components,
    uint16 _minMaxBp,
    uint16 _scoreAmplifierBp
) internal pure returns (uint256) {
    return _minMaxBp + uint256(M.expWad(
        -int256(_components) * int256(uint256(_scoreAmplifierBp).toWad())
    )).toBp();
}
```

### Example Maximum Weights

**Parameters**: minMaxBp=25%, diversificationFactorBp=0.3

| Number of Pools | Dynamic Max Weight | Effect |
|----------------|-------------------|--------|
| 1              | 99.3%            | Near-total allocation possible |
| 2              | 70.1%            | Strong concentration allowed |
| 4              | 49.8%            | Balanced distribution |
| 8              | 35.2%            | Moderate diversification |
| 16             | 27.7%            | Approaching minimum floor |

## Target Weight Calculation

### Exponential Score Weighting

Pool weights are calculated using exponential scaling of cScores:

```
rawWeight_i = cScore_i^(scoreAmplifierBp)
weight_i = rawWeight_i / Σ(rawWeight_j) × totalWeightBp
```

**Process:**
1. **Exponentiation**: Apply scoreAmplifierBp to amplify score differences
2. **Normalization**: Scale to sum to `totalWeightBp` (typically 100%)
3. **Capping**: Apply dynamic maximum weight constraints
4. **Redistribution**: Reallocate excess weight to uncapped pools

```solidity
function targetWeights(
  uint16[] memory _cScores,
    uint16 _maxWeightBp,
    uint16 _totalWeightBp,
    uint16 _scoreAmplifierBp
) internal pure returns (uint256[] memory weightsBp)
```

### Weight Capping and Redistribution

The system uses an iterative capping algorithm:

1. **Initial Calculation**: Compute uncapped weights from exponentiated scores
2. **Cap Detection**: Identify weights exceeding `maxWeightBp`
3. **Excess Collection**: Gather weight overflow from capped pools
4. **Redistribution**: Proportionally distribute excess to uncapped pools
5. **Iteration**: Repeat until no caps are violated

### Score Amplification Effects

| scoreAmplifierBp | Effect | Use Case |
|-----------------|---------|----------|
| 7500 (0.75x)   | Flattened distribution | Conservative diversification |
| 10000 (1.0x)   | Linear scaling | Balanced approach |
| 15000 (1.5x)   | Moderate concentration | Default strategy |
| 20000 (2.0x)   | High concentration | Quality-focused |
| 25000 (2.5x)   | Extreme concentration | Alpha-seeking |

## Target Allocation Implementation

### Amount Distribution

Final allocations multiply weights by the total amount to allocate:

```
allocation_i = totalAmount × weight_i / 10000
```

**Dust Handling**: Remaining wei from integer division is added to the largest allocation to ensure complete distribution.

```solidity
function targetAllocations(
    uint16[] memory _cScores,
  uint256 _amount,
    uint16 _maxWeightBp,
    uint16 _scoreAmplifierBp
) internal pure returns (uint256[] memory)
```

### Vault Integration

The system integrates with ALM vaults through:

```solidity
function almCScores(ALMVault storage _vault, Registry storage _reg) 
    internal view returns (uint16[] memory)
```

This function:
1. Retrieves range IDs from the vault
2. Maps ranges to their underlying pool IDs
3. Extracts cScores from the pool registry
4. Returns array of cScores for weight calculation

## Risk Management Features

### Concentration Limits

- **Individual Pool Cap**: No single pool exceeds `maxBp`
- **Dynamic Adjustment**: Maximum weights decrease with pool count
- **Quality Threshold**: Zero cScore pools receive zero allocation

### Diversification Incentives

- **Exponential Decay**: More pools → better diversification → lower individual caps
- **Balanced Scoring**: Geometric mean encourages well-rounded pools
- **Iterative Redistribution**: Ensures optimal use of available weight capacity

## Configuration Examples

### Conservative Configuration
```solidity
WeightModel({
    defaultCScore: 5000,        // 50% default
    scoreAmplifierBp: 10000,    // 1.0x (linear)
    minMaxBp: 3000,            // 30% min-max
    maxBp: 10000,              // 100% absolute max
    diversificationFactorBp: 5000 // 0.5 (strong diversification)
})
```

### Aggressive Configuration
```solidity
WeightModel({
    defaultCScore: 5000,        // 50% default
    scoreAmplifierBp: 20000,    // 2.0x (concentrated)
    minMaxBp: 1500,            // 15% min-max
    maxBp: 7500,               // 75% absolute max
    diversificationFactorBp: 1000 // 0.1 (weak diversification)
})
```

## Integration with Risk Management

The weight model integrates with other risk components:

- **Liquidity Model**: Ensures sufficient buffer liquidity for operations
- **Slippage Model**: Applies transaction-specific slippage based on ratio impact
- **Rebalancing**: Triggers allocation adjustments when weights drift from targets

## Performance Optimization

### Gas Efficiency

- **Batch Processing**: Calculate all weights in single transaction
- **Iterative Capping**: Converges quickly (typically 2-3 iterations)
- **Fixed-Point Math**: Uses WAD precision for accuracy without overflow

### Computational Complexity

- **Weight Calculation**: O(n) for uncapped weights
- **Capping Algorithm**: O(n × k) where k is iteration count (typically small)
- **Total Complexity**: O(n) practical performance for reasonable pool counts

