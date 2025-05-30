# MEV Protection & Front-Running Mitigation in BTR Protocol

This document outlines the BTR protocol's comprehensive strategies for protecting against Maximal Extractable Value (MEV) attacks, front-running, and sandwich attacks during ALM operations.

## 1. Overview of MEV Risks in ALM Protocols

### 1.1 Primary MEV Attack Vectors
- **Arbitrage Exploitation**: Using vault internal VWAP pricing to arbitrage against mispriced deposits/withdrawals  
- **Sandwich Attacks**: Front-running deposits/withdrawals with trades to manipulate vault ratios
- **Front-Running Rebalancing**: Copying profitable keeper operations before execution
- **VWAP Manipulation**: Exploiting temporal price discrepancies in vault pricing vs market

### 1.2 BTR-Specific Vulnerabilities
Since BTR vaults use internal VWAP for entry/exit pricing and allow deposits in any token ratio, there's potential for arbitrage when:
- Vault VWAP deviates from current market prices
- Deposit/withdrawal ratios differ significantly from vault target ratios
- Large operations create temporary imbalances

## 2. BTR Protocol MEV Protection Mechanisms

### 2.1 Protocol Upkeep Timing Protection

**Non-Deterministic Execution**: All protocol keeper operations (`onlyKeeper`) are executed at unpredictable times:
- `mintRanges()`: Range minting operations
- `burnRanges()`: Range burning operations  
- `swaps()`: Individual swap operations
- `rebalance()`: Comprehensive vault rebalancing

**BTR Swap Integration**: All swap operations use BTR Swap, a sophisticated liquidity aggregator that:
- Minimizes slippage by solving optimal routes across all available liquidity sources
- Combines passive pools (Uniswap V3/V4) with JIT liquidity (OTC, intent networks)
- Routes transactions through MEV-protected RPCs rather than public mempools
- Adapts to network architecture (e.g., Layer 2 sequencer-based chains with no mempool)

### 2.2 Slippage Protection Against VWAP Arbitrage

**Dynamic Slippage Curve**: The protocol implements configurable slippage protection based on ratio deviation:

```solidity
struct SlippageModel {
  uint16 minSlippageBp;     // Minimum slippage (e.g., 10 = 0.1%)
  uint16 maxSlippageBp;     // Maximum slippage (e.g., 500 = 5%)  
  uint16 amplificationBp;   // Curve shape parameter (0-10000 BPS)
}
```

**Curve Types**:
- **amplificationBp = 0-1000**: Pseudo-logarithmic (sharp increase for small deviations, then flattens)
- **amplificationBp = 1000-9000**: Linear interpolation between log and exponential
- **amplificationBp = 9000-10000**: Exponential (slow increase initially, then sharp growth)

**Implementation**:
```solidity
function calculateSlippage(int256 ratioDiff0, uint16 minSlippageBp, uint16 maxSlippageBp, uint16 amplificationBp) 
    internal pure returns (uint256 slippageBp)
```

### 2.3 Ratio-Based Fee Protection

**ratioDiff0 Calculation**: Measures how operations affect vault balance vs target ratio:
```solidity
function ratioDiff0(
    ALMVault storage _vault,
    Registry storage _reg, 
    uint256 _balance0,
    uint256 _balance1,
    int256 _diff0,
    int256 _diff1
) internal returns (int256 ratioDiff0)
```

**Protection Logic**:
- **Positive ratioDiff0**: Operation improves vault ratio → reduced fees
- **Negative ratioDiff0**: Operation worsens vault ratio → additional slippage applied
- **Magnitude**: Larger deviations incur exponentially higher costs

### 2.4 VWAP-Based Pricing Protection

**Internal VWAP Usage**: All deposit/withdrawal operations use vault internal VWAP rather than spot prices
**Price Staleness Protection**: Operations revert if VWAP becomes stale
**Temporal Smoothing**: VWAP calculation reduces impact of short-term price manipulation

## 3. Network-Specific Adaptations

### 3.1 Mainnet Ethereum
- Full MEV-protected RPC routing
- Private mempool submission for sensitive operations
- Advanced front-running protection

### 3.2 Layer 2 Networks  
- Sequencer-based chains: Direct submission to sequencer
- No public mempool exposure
- Reduced MEV risk due to centralized ordering

### 3.3 Alternative L1 Chains
- Network-specific MEV protection strategies
- Adapted routing based on validator behavior
- Custom RPC endpoint selection

## 4. Economic Security Model

### 4.1 Cost of Attack
The slippage protection makes MEV attacks economically unviable by:
- Increasing costs for ratio-destabilizing operations
- Making sandwich attacks unprofitable through dynamic fees
- Creating negative expected value for systematic arbitrage

### 4.2 Incentive Alignment
- Users depositing in target ratios pay minimal fees
- Operations improving vault balance receive fee reductions  
- Protocol sustainability through fair cost distribution

## 5. Monitoring & Response

### 5.1 Real-Time Detection
- Ratio deviation monitoring
- Slippage application tracking
- Unusual activity pattern detection

### 5.2 Parameter Adjustment
- Dynamic slippage model updates
- Response to market conditions
- Protection against evolving MEV strategies

## 6. Future Enhancements

### 6.1 Advanced Protection
- Machine learning-based MEV detection
- Cross-vault coordination for better protection
- Integration with additional MEV protection services

### 6.2 Network Evolution
- Adaptation to PBS (Proposer-Builder Separation)
- Integration with account abstraction
- Enhanced privacy through various mechanisms

This multi-layered approach provides comprehensive MEV protection while maintaining protocol efficiency and user experience. 
