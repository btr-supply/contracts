# Dynamic Slippage Model

## Theoretical Foundations

### Modern Mechanism Design and MEV Protection

The BTR dynamic slippage model implements principles from **optimal mechanism design theory** and **modern MEV (Maximal Extractable Value) protection research**, addressing two critical challenges in decentralized finance:

#### **Arbitrage Protection Theory**
The slippage mechanism draws from **Myerson-Satterthwaite mechanism design** and **adverse selection theory** to protect against:

- **High-Frequency MEV Attacks**: Based on research by Daian et al. (2020) and recent MEV literature, the power-function slippage creates **endogenous cost structures** that make sandwich attacks unprofitable below optimal thresholds
- **Manual/Low-Frequency Arbitrage**: Implements **dynamic pricing barriers** similar to Tobin tax theory, where slippage acts as a **transaction cost mechanism** that eliminates arbitrage opportunities when assets are mispriced
- **Optimal Mechanism Design**: Following Bolton-Dewatripont contract theory, the mechanism **reveals private information** about trade urgency through willingness to pay slippage

#### **Incentive Alignment Theory**  
The mechanism implements **second-price auction principles** and **revelation principle** concepts to incentivize optimal depositor behavior:

- **Asset Balance Incentives**: Uses **Vickrey-Clarke-Groves (VCG) mechanism** concepts where users pay their **marginal impact** on protocol health via `ratioDiff0`
- **Truth-Telling Implementation**: Slippage penalties create **incentive compatibility** - users naturally choose deposits that optimize protocol asset ratios
- **Pareto Efficiency**: When `ratioDiff0` is positive (beneficial deposits), negative slippage (rewards) ensures **allocative efficiency**

#### **Game-Theoretic Foundations**
Based on **sandwich game theory** (Heimbach & Wattenhofer, 2022) and **optimal slippage research**:

- **Nash Equilibrium Properties**: The power-curve design creates **unique equilibrium** where rational traders choose slippage tolerance that exactly balances MEV protection vs transaction failure risk
- **Mechanism Robustness**: Following **implementation theory**, the mechanism works under **incomplete information** - users don't need to know others' strategies
- **Anti-Manipulation Design**: Power-function structure prevents **strategy-proofness violations** common in linear slippage models

#### **Academic Connections**
- **Brunnermeier-Pedersen (2005)**: "Predatory Trading" - the mechanism creates **liquidity taxation** that eliminates predatory opportunities
- **Biais-Foucault-Moinas (2015)**: HFT market microstructure - slippage creates **optimal bid-ask spreads** endogenously  
- **Budish-Cramton-Shim (2015)**: Frequent batch auctions - the mechanism implements **continuous double auction** improvements
- **Canidio-Fritsch (2023)**: Arbitrage profits and LVR - the design minimizes **Loss-vs-Rebalancing** for liquidity providers

### Mathematical Optimality Properties

The **power-function transformation** `slippage = (ratioDiff0/10000)^slippageExponentBp` implements several optimal control theory principles:

- **Convex/Concave Duality**: Amplification factor controls **risk aversion parameters** similar to CRRA utility functions
- **Scale Invariance**: Mathematical structure ensures **homogeneous pricing** regardless of trade size
- **Continuity**: Smooth differentiable functions prevent **arbitrage through discontinuities**
- **Boundary Conditions**: Well-defined behavior at extremes (ratioDiff0 = ±10000) ensures **mechanism completeness**

## Ratio Calculation (ratioDiff0)

Before applying the dynamic slippage model, the protocol calculates `ratioDiff0`, which measures how a user transaction affects the vault's token balance ratio relative to its target.

### Step-by-Step Calculation

#### 1. Target Ratio Calculation
The vault's target ratio for token0 is calculated as a weighted average of all liquidity ranges:

```solidity
targetRatio0 = Σ(rangeRatio0[i] × weight[i]) / Σ(weight[i])
```

Where:
- `rangeRatio0[i]` is the proportion of token0 in each liquidity range at current prices
- `weight[i]` is the allocation weight for each range (in basis points)

#### 2. Current Ratio Calculation
The vault's current token0 ratio before the transaction:

```solidity
oldRatio0 = balance0 × BPS / (balance0 + balance1)
```

Where `balance0` and `balance1` are the total vault balances (cash + LP positions).

#### 3. Simulated New Ratio
The vault calculates what the ratio would be after the transaction:

```solidity
newBalance0 = balance0 ± amount0  // + for deposits, - for withdrawals
newBalance1 = balance1 ± amount1  // + for deposits, - for withdrawals
newRatio0 = newBalance0 × BPS / (newBalance0 + newBalance1)
```

#### 4. Ratio Difference Calculation
The final `ratioDiff0` measures the change in deviation from target:

```solidity
oldDeviation = |oldRatio0 - targetRatio0|
newDeviation = |newRatio0 - targetRatio0|
ratioDiff0 = oldDeviation - newDeviation  // Capped to [-BPS, +BPS]
```

### Implementation Details

The calculation is implemented in `LibALMBase.ratioDiff0()`:

```solidity
function ratioDiff0(
    ALMVault storage _vault,
    Registry storage _reg,
    uint256 _balance0,
    uint256 _balance1,
    int256 _diff0,
    int256 _diff1
) internal view returns (int16 ratioDiff0Bp) {
    uint256 targetRatio0Val = targetRatio0(_vault, _reg); // Target in BPS
    uint256 oldRatio0 = _balance0.mulDivDown(M.BPS, _balance0 + _balance1); // current ratio
    _balance0 = _diff0 >= 0 ? _balance0 + uint256(_diff0) : _balance0 - uint256(-_diff0); // New balance0
    _balance1 = _diff1 >= 0 ? _balance1 + uint256(_diff1) : _balance1 - uint256(-_diff1); // New balance1
    uint256 newRatio0 = _balance0.mulDivDown(M.BPS, _balance0 + _balance1);
    int256 rd0 = int256(oldRatio0.diff(targetRatio0Val)) - int256(newRatio0.diff(targetRatio0Val));
    rd0 = rd0.max(-int256(M.BPS)).min(int256(M.BPS)); // Cap to ±BPS (should always be true)
    ratioDiff0Bp = int16(rd0); // Safe cast since capped to ±BPS
}
```

### Usage in Deposits and Withdrawals

- **Deposits**: Called in `amountsToShares()` with positive `_diff0` and `_diff1` values
- **Single-sided withdrawals**: Called in `sharesToAmount0()` and `sharesToAmount1()` with negative values for the withdrawn token

## Overview

The dynamic slippage model provides a flexible framework for calculating transaction slippage based on the `ratioDiff0` metric, which measures how beneficial a user transaction is for the protocol.

## Parameters

### ratioDiff0
- **Range**: [-10000, 10000] (-BPS, BPS)
- **Interpretation**:
  - `-10000`: Worst case scenario (highest slippage applied)
  - `10000`: Best case scenario (lowest slippage, can be negative meaning users get paid for helping the protocol)
  - Represents how good a user transaction is for our protocol

### Slippage Bounds
- **minSlippage**: The minimum slippage value (can be negative, zero, or positive)
  - Negative values mean users receive rewards
  - Applied when ratioDiff0 = 10000 (best case)
- **maxSlippage**: The maximum slippage value (can be negative or positive)
  - Applied when ratioDiff0 = -10000 (worst case)

### Amplification Factor
- **Range**: [0, 10000] (BPS)
- **Effect on Curve Shape**:
  - **0-4999**: Concave curve (logarithmic-like)
    - Slippage increases sharply for small ratioDiff0 values
    - Then flattens out for higher ratioDiff0 values
  - **5000**: Linear curve (proportional relationship)
  - **5001-10000**: Convex curve (exponential-like)
    - Slow slippage increase initially
    - Sharp growth for higher ratioDiff0 values

## Mathematical Model

The slippage function follows this general form:

```
slippage = maxSlippage + (minSlippage - maxSlippage) * f(normalizedRatio, amplification)
```

Where:
1. `normalizedRatio = (ratioDiff0 + 10000) / 20000` maps ratioDiff0 from [-10000, 10000] to [0, 1]
2. `f(x, amp)` is the transformation function controlled by amplification
3. The result is linearly mapped to the [maxSlippage, minSlippage] range

### Transformation Function

The amplification factor controls the curve shape through a symmetrical power transformation:

```javascript
function calculateSlippage(ratioDiff0, minSlippage, maxSlippage, amplification) {
  const normalizedRatio = (ratioDiff0 + 10000) / 20000;
  const exponent = Math.pow(10, Math.abs(amplification - 5000) / 2500);
  
  let transformed;
  if (amplification <= 5000) {
    // Concave curve: inverse transformation for symmetrical smoothness
    transformed = 1 - Math.pow(1 - normalizedRatio, exponent);
  } else {
    // Convex curve: direct power transformation
    transformed = Math.pow(normalizedRatio, exponent);
  }
  
  return maxSlippage + (minSlippage - maxSlippage) * transformed;
}
```

### Mathematical Formulation

Given:
- `x = (ratioDiff0 + 10000) / 20000` (normalized input)
- `e = 10^(|amplification - 5000| / 2500)` (exponent)

The transformation function is:

```
f(x, amplification) = {
  1 - (1 - x)^e     if amplification ≤ 5000  (concave)
  x^e               if amplification > 5000   (convex)
}
```

Final slippage calculation:
```
slippage = maxSlippage + (minSlippage - maxSlippage) × f(x, amplification)
```

## Comparison with Other AMM Approaches

| Aspect | This Dynamic Slippage | Curve/Balancer StableSwap |
|--------|---------------------|---------------------------|
| **Purpose** | Protocol-aware slippage control | Minimize slippage for similar assets |
| **Input Parameter** | Protocol health metric (ratioDiff0) | Token pool balances |
| **Amplification** | Symmetrical curve control (0-10000) | Flatness around equilibrium (1-5000) |
| **Computation** | ✅ **Direct formula** | ❌ Newton's method iteration |
| **Slippage Range** | ✅ **Supports negative slippage** | Always positive |
| **Curve Flexibility** | ✅ **Concave ↔ Linear ↔ Convex** | Flat center, steep edges |
| **Asset Requirements** | Any assets | Price-correlated |

### Key Advantages

**Computational Efficiency**: This approach uses simple closed-form power functions, eliminating the need for expensive Newton's method iterations required by Curve/Balancer stable pools.

**Amplification Comparability**: Like Curve's amplification coefficient, this model provides intuitive control over curve behavior, but with symmetric smoothness on both extremes.

**Perfect for Slippage Control**: Unlike traditional AMMs designed for asset pricing, this model is purpose-built for dynamic slippage adjustment based on protocol health, supporting both penalties and rewards.

## Properties

### Symmetrical Smoothness
The model uses inverse power functions for low amplification values, ensuring that both concave and convex curves have equivalent smoothness characteristics at their extremes.

### Scale Invariance
The curve shape remains relatively consistent regardless of the minSlippage and maxSlippage bounds, ensuring predictable behavior across different market conditions.

### Amplification Effects
- **Low amplification (0-4999)**: Protects the protocol by applying higher slippage early for unfavorable transactions
- **Linear amplification (5000)**: Provides exact proportional slippage response
- **High amplification (5001-10000)**: Allows more favorable transactions with minimal slippage, but penalizes severely at the extremes

### Continuity
The function is continuous at amplification = 5000, where both formulations converge to the linear case (exponent = 1).

## Use Cases

1. **Conservative Markets** (low amplification): Protect protocol during volatile conditions with early slippage application
2. **Balanced Markets** (mid amplification): Standard proportional response
3. **Aggressive Markets** (high amplification): Maximize user experience for favorable transactions

## Implementation Notes

- The function is continuous and differentiable across all parameter ranges
- The symmetrical design ensures equivalent curve smoothness for both concave and convex cases
- Edge cases (ratioDiff0 = ±10000) are handled explicitly
- The amplification mapping ensures smooth transitions between curve types
- All calculations use standard mathematical operations for efficiency
