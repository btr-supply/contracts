# VWAP Calculation

This document explains how the Volume Weighted Average Price (VWAP) is calculated for each vault in the protocol.

## Overview

The VWAP represents the average price of token0 denominated in token1, weighted by the liquidity distribution across the different ranges within a vault. It provides a single, representative price for the vault'''s assets.

## Implementation Details

The core logic for VWAP calculation resides in the `LibALMBase.sol` library. It offers three overloaded `vwap` functions:

1.  **`vwap(RangeParams[] memory _ranges, Registry storage _reg, bool _safe)`**:
    *   This function calculates the VWAP based on an array of `RangeParams`. Each `RangeParams` struct contains the `poolId` and `weightBp` (weight in basis points) for a specific range.
    *   It iterates through the provided ranges. For each range with a non-zero weight:
        *   It fetches the current price of the pool associated with the `poolId`. It can use either `poolPrice` for the current spot price or `safePoolPrice` which checks for stale prices (reverting if the price has drifted more than 2% in the last 15 minutes when `_safe` is true).
        *   It multiplies this price by the range'''s `weightBp`.
        *   It accumulates the `weightedSum` and `totalWeightBp`.
    *   Finally, it calculates the VWAP by dividing the `weightedSum` by the `totalWeightBp`.
    *   If `_safe` is true and the calculated `price` is 0, it reverts with `Errors.StalePrice()`.
    *   Relevant code: [`LibALMBase.sol#L500-L522`](../evm/src/libraries/LibALMBase.sol#L500-L522)

2.  **`vwap(bytes32[] storage _rids, Registry storage _reg, bool _safe)`**:
    *   This function calculates the VWAP based on an array of range IDs (`_rids`) stored in storage.
    *   It iterates through the range IDs. For each valid range with a non-zero weight:
        *   It fetches the `Range` struct from the `Registry`.
        *   It retrieves the pool price (either `poolPrice` or `safePoolPrice` based on the `_safe` flag) for the range'''s `poolId`.
        *   It multiplies the pool price by the range'''s `weightBp`.
        *   It accumulates the `weightedSum` and `totalWeightBp`.
    *   The final VWAP is `weightedSum / totalWeightBp`.
    *   If `_safe` is true and the calculated `price` is 0, it reverts with `Errors.StalePrice()`.
    *   If there are no ranges (`rangeCount == 0`), it returns 0.
    *   Relevant code: [`LibALMBase.sol#L530-L556`](../evm/src/libraries/LibALMBase.sol#L530-L556)

3.  **`vwap(ALMVault storage _vault, Registry storage _reg)`**:
    *   This is a convenience function that calculates the VWAP for a given `ALMVault`.
    *   It simply calls the second `vwap` function, passing the vault'''s `ranges` (an array of `bytes32` range IDs) and the `_reg`.
    *   By default, this version does not use the `_safe` price check.
    *   Relevant code: [`LibALMBase.sol#L563-L565`](../evm/src/libraries/LibALMBase.sol#L563-L565)

## Exposure in ALMInfoFacet

The VWAP calculation is exposed externally through the `ALMInfoFacet.sol` contract.

*   **`vwap(uint32 _vid) external returns (uint256)`**:
    *   This function allows users to query the VWAP for a specific vault identified by `_vid`.
    *   It retrieves the `ALMVault` storage for the given `_vid` and calls the internal `vault.vwap(S.reg())` function, which in turn uses the third implementation from `LibALMBase.sol` mentioned above.
    *   Relevant code: [`ALMInfoFacet.sol#L415-L417`](../evm/src/facets/ALMInfoFacet.sol#L415-L417)

## Price Representation (WAD Scale)

The prices used in VWAP calculations, and the resulting VWAP itself, are represented as `uint256` values scaled by WAD (1e18). This approach was chosen over Uniswap-style Q64.96 fixed-point numbers for several reasons:

*   **Efficiency in Computations**:
    *   **Avoids Squaring**: Q64.96 prices are square roots of real prices. Calculating a real price requires squaring the `sqrtPriceX96` (`price = (sqrtPriceX96^2 * 1e18) / 2^192`), which is a computationally expensive operation to perform for each data point in a VWAP calculation. WAD-scaled prices are direct representations, avoiding this overhead.
    *   **Fewer Bitwise Shifts**: Q64.96 arithmetic often involves numerous bitwise shifts (e.g., `<< 96`, `>> 96`) or divisions by `2^192`. WAD-scaled `uint256` integers allow for more straightforward arithmetic (`weightedSum += price * volume`), reducing gas costs and improving clarity.
*   **Reduced Arithmetic Overhead**:
    *   Working with `uint256` WAD prices avoids expensive casting between `uint160` (for Q64.96) and `uint256`.
    *   It also minimizes the risk of overflow that can occur in fixed-point math, especially during squaring or inverting `sqrtPriceX96`.
*   **Readability**: WAD-scaled prices are integers representing standard decimal values (scaled by 1e18), which are generally easier to understand and debug than fixed-point numbers requiring specific transforms for interpretation.

In summary, using WAD-scaled `uint256` prices for VWAP calculations is more gas-efficient, numerically stable, and easier to work with compared to Q64.96 prices in this context. Prices are either stored directly in WAD scale or converted once from Q64.96 to WAD before being used in VWAP aggregation.

---
