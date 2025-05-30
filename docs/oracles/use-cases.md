# Oracle System

## Overview
This document describes the architecture for integrating on-chain and off-chain price feeds into the BTR protocol. We support multiple oracle providers (Chainlink, Pyth, Uniswap V3, etc.) through a common interface.

## Storage & Routing
The Diamond's central storage tracks which provider is responsible for which asset, with lookback periods and validity settings:

```
mapping(bytes32 => uint256) validityByFeed // Maps token → feed validity period
mapping(bytes32 => address) provider // Maps token → provider implementation
```

## Core Components

### Provider System
- `PriceProvider.sol` - Abstract base contract for price feed providers
- Provider implementations in `adapters/oracles/`:
  - `ChainlinkProvider.sol` - Chainlink price feeds
  - `PythProvider.sol` - Pyth Network price feeds
  - `UniV3Provider.sol` - Uniswap V3 TWAP feeds
  - `AlgebraV3Provider.sol` - Algebra V3 TWAP feeds

### Protocol Integration
- `OracleProtectedFacet.sol` - Management functions for providers and feeds
- `OracleInfoFacet.sol` - Read-only access to oracle data
- `PriceAwareFacet.sol` - Helper for contracts to consume oracle data

## Workflow Examples

### Registration Flow
1. Admin registers provider for an asset:
   ```
   oracleProtected.setProvider(WETH, chainlinkProviderAddress);
   ```

2. Manager configures the feed:
   ```
   bytes32 feedId = bytes32(uint256(uint160(aggregatorAddress)));
   oracleProtected.setFeed(WETH, feedId, 3600); // 1 hour validity
   ```

### Consumption Flow
1. Via OracleInfoFacet (for external callers):
   ```
   uint256 ethPrice = oracleInfo.toUsd(WETH);
   ```

2. Via PriceAwareFacet (for internal contracts):
   ```
   function execute() external whenPriceAware {
     uint256 price = toUsd(WETH);
     // use price
   }
   ```

## Error Handling & Validation
- `isPriceStale()` - Checks if price age exceeds validity period
- `isPriceDeviating()` - Checks if price deviates from TWAP too much
- Fallback providers can be configured for each asset

## Extension Points
- Cross-provider failover
- Weighted price averages
- Historical price storage 
