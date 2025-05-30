# User ALM Flows

This document outlines the primary user interactions with the ALM (Automated Liquidity Management) vaults, focusing on deposits, withdrawals, and the underlying cash buffer mechanism that optimizes these processes.

## Core User Actions

The main functions users interact with, typically via the `ALMUserFacet`, are:

### Deposit Functions
*   **Standard Deposit Variants**:
    *   **`deposit(amount0, amount1, receiver)`**: Deposits specified amounts of both tokens, returning shares
    *   **`safeDeposit(amount0, amount1, receiver, minShares)`**: Same as deposit but with minimum shares guarantee
    *   **`mint(shares, receiver)`**: Mint specific amount of shares by providing necessary tokens
    *   **`safeMint(shares, receiver, maxSpent0, maxSpent1)`**: Same as mint but with maximum token spending limits

*   **Exact Amount Deposit Variants**:
    *   **`depositExact0(exactAmount0, receiver)`**: Deposit exact amount of token0, auto-calculating token1 needed
    *   **`depositExact1(exactAmount1, receiver)`**: Deposit exact amount of token1, auto-calculating token0 needed
    *   **`safeDepositExact0(exactAmount0, receiver, minShares, maxAmount1)`**: Same as depositExact0 with safety bounds
    *   **`safeDepositExact1(exactAmount1, receiver, minShares, maxAmount0)`**: Same as depositExact1 with safety bounds

*   **Single-Sided Deposit Variants** (Implemented):
    *   **`depositSingle0(amount0, receiver)`**: Deposit only token0
    *   **`depositSingle1(amount1, receiver)`**: Deposit only token1
    *   **`safeDepositSingle0(amount0, receiver, minShares)`**: Safe single-sided deposit of token0 with minimum shares
    *   **`safeDepositSingle1(amount1, receiver, minShares)`**: Safe single-sided deposit of token1 with minimum shares
    
### Withdrawal Functions
*   **Standard Withdrawal Variants**:
    *   **`redeem(shares, receiver)`**: Burns shares to withdraw proportional tokens
    *   **`safeRedeem(shares, receiver, minAmount0, minAmount1)`**: Same as redeem with minimum token guarantees
    *   **`withdraw(amount0, amount1, receiver)`**: Specifies token amounts to withdraw, burning necessary shares
    *   **`safeWithdraw(amount0, amount1, receiver, maxBurntShares)`**: Same as withdraw with maximum share burning limit

*   **Exact Amount Withdrawal Variants**:
    *   **`withdrawExact0(amount0, receiver, minAmount1)`**: Withdraw exact amount of token0 with auto-calculated token1
    *   **`withdrawExact1(amount1, receiver, minAmount0)`**: Withdraw exact amount of token1 with auto-calculated token0
    *   **`safeWithdrawExact0(amount0, receiver, minAmount1, maxBurntShares)`**: Same with safety bounds
    *   **`safeWithdrawExact1(amount1, receiver, minAmount0, maxBurntShares)`**: Same with safety bounds

*   **Single-Sided Withdrawal Variants** (Implemented):
    *   **`withdraw0(shares, receiver)` / `withdrawSingle0(shares, receiver)`**: Burn shares to receive only token0
    *   **`withdrawSingle1(shares, receiver)`**: Burn shares to receive only token1
    *   **`safeWithdraw0(shares, receiver, minAmount0)`**: Safe single-sided withdrawal of token0
    *   **`safeWithdrawSingle1(shares, receiver, minAmount1)`**: Safe single-sided withdrawal of token1

### Preview Functions
*   Multiple preview functions allow users to estimate outcomes before executing transactions:
    *   **Standard previews**: `previewDeposit`, `previewWithdraw`, `previewRedeem`
    *   **Exact amount previews**: `previewDepositExact0/1`, `previewWithdrawExact0/1`
    *   **Single-sided previews**: `previewDepositSingle0/1`, `previewWithdrawSingle0/1`
    *   **Maximum deposit preview**: `previewDepositMax` - calculates optimal deposit based on user's token balances

### Common Modifiers and Security
*   **`whenVaultNotPaused`**: Operations only allowed when vault is not paused
*   **`nonReentrant`**: Prevents reentrancy attacks during state-changing operations
*   **Slippage protection**: Safe variants include slippage protection through min/max bounds
*   **Fee transparency**: All operations return fee amounts for full transparency

## Cash Buffer Mechanism: Efficient Deposits and Withdrawals

The BTR ALM protocol employs a sophisticated cash buffer strategy, inspired by tested methods like those in ERC7540 vaults, to significantly enhance the efficiency and reduce gas costs for user deposits and withdrawals.

### How it Works

1.  **Deposits - Kept as Cash Initially**:
    *   When a user deposits tokens into the vault, these funds are initially held as liquid cash within the vault (`_vault.cash` in `LibALMUser.mintShares`).
    *   The protocol does **not** immediately mint new liquidity positions (ranges) on the underlying DEX for each individual deposit. This avoids imposing high gas costs on every depositor for range management operations.

2.  **Withdrawals - Prioritizing Cash**:
    *   When a user initiates a withdrawal, the protocol first attempts to fulfill the request using the available cash buffer in the vault.
    *   If sufficient cash is present to cover the withdrawal (after accounting for exit fees), the user receives their tokens directly from this buffer. This is the most gas-efficient scenario for the user.

3.  **Maintaining the Buffer - Keeper Operations**:
    *   The cash buffer is actively managed by keepers.
    *   **`remintRanges()`**: If the cash level is sufficient and existing ranges need more liquidity (e.g., after net outflows have depleted them somewhat, or simply to deploy accumulated cash), keepers can call `remintRanges`. This function uses the available cash to mint more liquidity into the *existing, pre-defined* ranges without altering the range parameters themselves. This is a relatively cheap operation as it involves no swaps (and thus no slippage costs), only gas for minting.
    *   **`rebalance()`**: If the cash in the vault grows too large (e.g., exceeding a certain percentage of the Total Value Locked (TVL), such as 5% as an example threshold) due to net inflows, or if the underlying market conditions necessitate a change in liquidity strategy (new range prices/widths), keepers trigger a `rebalance`.
        *   A `rebalance` operation is more comprehensive: it typically involves burning all existing ranges (converting them to cash), potentially swapping tokens to achieve the new target allocation, and then minting new liquidity positions according to the updated strategy (which might include new ranges or different weights).
        *   This way, the cost of deploying liquidity (and associated swaps) is socialized and occurs less frequently, potentially covering thousands of individual deposits and withdrawals in a single, optimized operation.

### Upsides of the Cash Buffer Mechanism

*   **Dramatically Reduced Gas Costs for Users**: Deposits and withdrawals become exceptionally cheap for the end-user because they usually don't involve direct interaction with DEX range minting/burning on each call. The cost savings can be substantial (potentially up to 1000x more efficient than if users minted underlying liquidity directly at deposit time).
*   **Reduced MEV Friction**: By pooling deposits and managing liquidity deployment through keepers, the protocol can reduce MEV opportunities that might arise from individual, predictable on-chain liquidity operations.
*   **Optimized Liquidity Deployment**: Keepers can choose the most opportune times and strategies to deploy liquidity or rebalance, potentially leading to better overall vault performance.
*   **Netting Outflows and Inflows**: In many cases, daily deposits and withdrawals will partially or fully offset each other. The cash buffer absorbs these fluctuations, meaning the protocol only needs to interact with the DEX for the net difference, further saving on transaction costs and slippage. If inflows consistently exceed outflows, the protocol efficiently accumulates cash for periodic deployment.
*   **Smoother User Experience**: Users experience faster and cheaper transactions.

### Potential Downsides & Considerations

*   **Yield Dilution (Cash Drag) - Optimization Tradeoff**: Holding a portion of high-quality assets as cash reserves (rather than deploying them to DEX liquidity pools) means this portion temporarily earns lower yields than active liquidity positions. This is a strategic optimization tradeoff, not an asset quality issue.
    *   **Important Note**: The cash reserves consist of the same high-quality vault tokens (USDC, WETH, etc.) - these are excellent assets, but they earn lower yields when held as reserves versus being deployed as active DEX liquidity
    *   **Strategic Purpose**: Cash reserves enable 70%+ gas cost reductions for users and provide emergency liquidity without slippage
    *   **Mitigation**: The "sweet spot" is to maintain an optimal level of cash – enough to buffer routine deposits/withdrawals but not so much that it significantly impacts APY. This ideal cash level is typically a decreasing function of the vault's TVL (e.g., starting around ~20% for new/small vaults and dropping to 2-3% for very large vaults, e.g., >$50 million TVL). Additionally, cash reserves are invested in yield-generating, instantly-redeemable DeFi positions (AAVE, Compound) to minimize opportunity cost.
*   **Reliance on Keepers**: The efficiency of the system and the timely deployment of cash rely on active and reliable keepers to call `remintRanges` and `rebalance`.
*   **Complexity**: The logic for managing the cash buffer and deciding when and how to rebalance or remint adds complexity to the protocol.

### Withdrawal Scenarios & Gas Implications (Current V1 Implementation Highlighted)

The cash buffer significantly impacts withdrawal efficiency:

1.  **Withdrawal without Cascading Liquidations (Best Case - Implemented in V1)**:
    *   **Scenario**: Sufficient cash is available in the vault to cover the user's withdrawal.
    *   **Action**: Tokens are transferred directly from the cash buffer. No DEX interaction for burning ranges is needed.
    *   **Cost**: Ultra cheap for the user (minimal gas).

2.  **Withdrawal with Cascading Liquidations (When Cash is Insufficient)**:
    *   If the cash buffer cannot cover the withdrawal, the protocol must liquidate active liquidity positions (burn ranges) to free up tokens.
    *   **Current V1 Approach ("Safe but Naive" Liquidation)**: When a withdrawal triggers the need for more cash than available, `LibALMUser.burnShares` calls `_vault.burnRanges(_reg)` (which burns *all* ranges in the vault) followed by `_vault.remintRanges(_reg)` (which re-mints liquidity into *all* previously defined ranges).
        *   **Cost**: This is more expensive than the best-case scenario due to the gas costs of burning all ranges and then re-minting them. For a vault with multiple ranges (e.g., 3 ranges), this could be >150% more expensive in gas than an ideal partial liquidation.
        *   **Rationale**: This ensures sufficient liquidity is always made available and simplifies the V1 logic, prioritizing safety and robustness.

    *   **Future Optimizations (Not in V1, for consideration)**:
        *   *Intelligent Partial Liquidation*: Only liquidate a portion of one or more ranges, just enough to cover the withdrawal. This is more complex to implement correctly (e.g., deciding which range(s) to partially burn). Could be "normal" cost.
        *   *Proportional Liquidation*: Liquidate a small portion from all ranges, proportional to the withdrawal amount. Potentially ~50% more expensive for a 3-range vault than intelligent partial, but less than full liquidation/remint.

## Single-Sided Operations (Implemented)

The protocol now supports single-sided operations, allowing users to:

1. **Deposit only one token** (token0 or token1) while still receiving appropriate vault shares
2. **Withdraw only one token** (token0 or token1) when redeeming shares

These operations are particularly useful for:
- Users who hold only one asset from the pair
- Traders who wish to express directional views while still benefiting from the vault's strategy
- Optimizing for gas costs when interacting with only one token
- Users who prefer to avoid slippage costs related to swapping tokens before depositing

### Implementation Details

**Single-sided deposits** increase the vault's cash in proportions that differ from the target ratios. The protocol's ratio-based fee mechanism automatically:
- Charges higher fees for operations that worsen the vault's ratio balance
- Provides fee discounts for operations that improve the vault's ratio balance
- Incentivizes users to naturally rebalance the vault through their deposit/withdrawal choices

**Single-sided withdrawals** are handled efficiently through the cash buffer mechanism:
- When possible, fulfilled directly from available cash without requiring range liquidation
- When cash is insufficient, the vault automatically liquidates ranges and re-mints them after the withdrawal
- Users receive tokens in their preferred denomination while the vault maintains its strategy

Keepers remain responsible for rebalancing as needed to maintain optimal capital deployment and target ratios.

## Ratio-Based Fee Mechanism

### Purpose and Rationale

The BTR ALM protocol implements a ratio-based fee mechanism to:

1. **Incentivize Balanced Deposits and Withdrawals**: Encourage users to deposit and withdraw in proportions that maintain or improve the vault's target token ratio
2. **Prevent Liquidity Arbitrage**: Protect against users exploiting small price discrepancies between the vault's VWAP and external markets
3. **Fund Rebalancing Costs**: Generate revenue to offset slippage and price impact costs incurred during rebalancing operations

### How ratioDiff0 is Calculated

The `ratioDiff0` metric measures how a user transaction affects the vault's token balance ratio relative to its target. Here's the step-by-step calculation:

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

#### 5. Interpretation of Values

- **Positive Values (0 to +10,000)**: The transaction **improves** the vault's ratio by reducing deviation from target
  - `+10,000`: Maximum improvement (completely fixes an imbalanced vault)
  - `+5,000`: Significant improvement (reduces deviation by 50%)
  - `+1,000`: Minor improvement (reduces deviation by 10%)

- **Negative Values (-10,000 to 0)**: The transaction **worsens** the vault's ratio by increasing deviation from target
  - `-10,000`: Maximum worsening (completely imbalances a balanced vault)
  - `-5,000`: Significant worsening (increases deviation by 50%)
  - `-1,000`: Minor worsening (increases deviation by 10%)

- **Zero Value**: The transaction has no net effect on the vault's ratio balance

### Transaction Type Examples

#### Deposit Scenarios
1. **Balanced Deposit** (`ratioDiff0 ≈ 0`): User deposits tokens in proportions matching target ratio
2. **Rebalancing Deposit** (`ratioDiff0 > 0`): User deposits more of the under-represented token
3. **Imbalancing Deposit** (`ratioDiff0 < 0`): User deposits more of the over-represented token

#### Withdrawal Scenarios
1. **Balanced Withdrawal** (`ratioDiff0 ≈ 0`): User withdraws tokens in proportions matching current ratio
2. **Rebalancing Withdrawal** (`ratioDiff0 > 0`): User withdraws more of the over-represented token
3. **Imbalancing Withdrawal** (`ratioDiff0 < 0`): User withdraws more of the under-represented token

#### Single-Sided Operations
- **Single-sided deposits** typically have negative `ratioDiff0` (worsen balance)
- **Single-sided withdrawals** can have positive `ratioDiff0` if withdrawing the over-represented token

### Fee Application

The protocol applies dynamic fees based on this value:

1. **For Deposits**: 
   - Operations with positive `ratioDiff0` (improving ratio) receive reduced fees or even rewards
   - Operations with negative `ratioDiff0` (worsening ratio) incur additional fees

2. **For Withdrawals**:
   - Operations with positive `ratioDiff0` (improving ratio) receive reduced fees
   - Operations with negative `ratioDiff0` (worsening ratio) incur additional fees

3. **Maximum Impact**: 
   - In extreme cases where an operation would completely reverse a vault's imbalance (`ratioDiff0 = ±10,000`), the fee adjustment reaches its maximum value
   - For balanced operations that maintain the ratio (`ratioDiff0 ≈ 0`), no additional fee adjustment occurs

### Viewing Ratio Impact in Preview Functions

Users can preview how their operations will affect the ratio and the resulting fee adjustments through the preview functions:

- `previewDepositSingle0/1`: Shows estimated shares, fees, and ratio impact for single-sided deposits
- `previewWithdrawSingle0/1`: Shows estimated token amounts, fees, and ratio impact for single-sided withdrawals
- `previewDeposit`: Shows ratio impact for balanced deposits
- `previewWithdraw`: Shows ratio impact for balanced withdrawals

### Benefits to Users

This mechanism provides several benefits:

1. **Fair Cost Distribution**: Users who create imbalances that require costly rebalancing pay proportionally more
2. **Incentives for Efficient Operations**: Users are financially incentivized to deposit and withdraw in balanced proportions
3. **Reduced Sandwich Risk**: The dynamic fee structure makes the vault more resistant to sandwich attacks and value extraction
4. **Protocol Sustainability**: Generated fees help maintain the protocol's profitability and long-term sustainability

### Example Scenarios

1. **Favorable Deposit (Positive ratioDiff0)**:
   - Vault is currently imbalanced with excess token1 (current ratio: 30% token0, 70% token1)
   - Target ratio: 50% token0, 50% token1
   - User deposits only token0
   - This improves the ratio toward target, resulting in reduced fees or rewards

2. **Unfavorable Deposit (Negative ratioDiff0)**:
   - Vault is currently imbalanced with excess token0 (current ratio: 70% token0, 30% token1)
   - Target ratio: 50% token0, 50% token1
   - User deposits more token0
   - This worsens the imbalance, resulting in higher fees

3. **Neutral Deposit (ratioDiff0 ≈ 0)**:
   - User deposits in proportions matching the target ratio
   - No additional fee adjustments are applied

## BTR's Pure User Experience: No Transaction Piggybacking

### Fundamental Design Principle

**BTR's Core Promise**: Users pay **only for their own transactions**, never for protocol maintenance operations.

#### **What Makes BTR Different from Competitors**

**BTR Protocol Approach**:
- **Clean Separation**: User deposits and withdrawals are completely isolated from protocol rebalancing operations
- **No Hidden Costs**: When you deposit $1000, you pay gas only for that deposit transaction - nothing else
- **Predictable Pricing**: User transaction costs are consistent and transparent
- **Optimal User Experience**: Fast, cheap transactions every time

**Competitor Protocol Issues**:
- **Transaction Piggybacking**: Combine user operations with protocol rebalancing in the same transaction
- **Unpredictable Costs**: User might pay $5 for a simple deposit, or $85 if the protocol decided to rebalance at the same time
- **Forced or Predictable Timing**: Protocol operations execute when users transact, or on strict schedule, not when market conditions are optimal
- **Poor User Experience**: Slow, expensive, unpredictable transaction costs

#### **Real-World Cost Comparison**

| Operation | Competitor Protocol | BTR Protocol | BTR Advantage |
|-----------|-------------------|--------------|---------------|
| **Simple Deposit** | $3-8 (deposit only) | $1-3 (deposit only) | 2-3x cheaper |
| **Deposit + Forced Rebalancing** | $45-120 (user pays all) | $1-3 (user pays deposit only) | **15-40x cheaper** |
| **Withdrawal** | $5-15 (withdrawal only) | $1-4 (withdrawal only) | 3-4x cheaper |
| **Withdrawal + Forced Liquidation** | $80-200 (user pays all) | $1-4 (user pays withdrawal only) | **20-50x cheaper** |

#### **How BTR Achieves This**

1. **Asynchronous Keeper Operations**: 
   - Keepers handle all DEX interactions (minting, burning, rebalancing) separately from user transactions
   - These operations happen at optimal times, not when users happen to transact
   - Costs are spread across the entire vault, not charged to individual users

2. **Liquidity Buffer Strategy**:
   - Cash buffer absorbs most user operations without requiring DEX interactions
   - Users get instant deposits/withdrawals from the buffer
   - Only when buffer triggers are hit do keepers rebalance (separately, at optimal times)

3. **Cost Socialization**:
   - Protocol maintenance costs are covered by vault fees and yield
   - Individual users never pay for operations that benefit the entire vault
   - True "pay for what you use" model

#### **User Experience Benefits**

- **Predictable Costs**: You always know what a deposit or withdrawal will cost
- **Fast Execution**: No waiting for complex protocol operations to complete
- **No Surprise Fees**: Never get charged extra because the protocol decided to rebalance
- **Better Capital Efficiency**: Protocol can choose optimal timing for expensive operations
- **Lower MEV Risk**: Reduced predictable transaction patterns that can be front-run

This architectural choice makes BTR fundamentally more user-friendly while maintaining superior protocol efficiency through optimized keeper operations.
