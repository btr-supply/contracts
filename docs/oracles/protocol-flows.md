# Oracle Protocol Flows

This document outlines the oracle management and data feed operations within the BTR protocol, focusing on price provider configuration, feed management, and oracle adapter deployment performed by managers and automated systems.

## Overview

The BTR oracle system provides decentralized price feeds for multi-chain ALM operations through:

- **Price Providers**: Abstract contracts implementing price conversion logic
- **Oracle Adapters**: Network-specific implementations (Chainlink, Uniswap, etc.)
- **Feed Management**: Configuration and validation of price sources
- **Fallback Mechanisms**: Alternative providers for redundancy

## Oracle Architecture

### Core Components

```mermaid
graph TD
    A[OracleFacet] --> B[LibOracle]
    B --> C[Price Providers]
    C --> D[Oracle Adapters]
    D --> E[External Oracles]
    
    C --> F[ChainlinkProvider]
    C --> G[UniswapProvider]
    C --> H[CustomProvider]
    
    F --> I[Chainlink Aggregators]
    G --> J[Uniswap Pools]
    H --> K[Custom Sources]
```

### Provider Hierarchy

- **PriceProvider**: Base abstract contract with USD conversion logic
- **OracleAdapter**: Base abstract contract with feed management
- **Specific Implementations**: ChainlinkProvider, UniswapProvider, etc.

## Oracle Initialization

### 1. Oracle System Setup

```mermaid
graph TD
    A[Deploy Oracle System] --> B[Initialize OracleFacet]
    B --> C[Set Core Token Addresses]
    C --> D[Configure Default Parameters]
    D --> E[Deploy Provider Adapters]
    E --> F[Register Initial Feeds]
```

**Function**: `OracleFacet.initializeOracle()`

**Parameters**:
```solidity
struct CoreAddresses {
    address weth;
    address usdc;
    address usdt;
    address btc;
    // Other core protocol tokens
}
```

## Provider Management

### 1. Provider Registration

```mermaid
graph TD
    A[Manager calls setProvider] --> B[Validate provider address]
    B --> C[Check provider interface]
    C --> D[Store provider configuration]
    D --> E[Update provider parameters]
    E --> F[Emit ProviderUpdated event]
```

**Function**: `OracleFacet.setProvider()`

**Provider Setup**:
- **New Provider**: `setProvider(address _provider, bytes _params)`
- **Replace Provider**: `setProvider(address _provider, address _replacing, bytes _params)`

### 2. Provider Removal

```mermaid
graph TD
    A[Manager calls removeProvider] --> B[Check no active feeds]
    B --> C[Validate provider exists]
    C --> D[Remove provider mapping]
    D --> E[Clean up configuration]
```

**Function**: `OracleFacet.removeProvider()`

**Validation**:
- Provider must have no active feeds
- Only managers can remove providers
- Cleanup of associated configuration

## Feed Management

### 1. Feed Registration

```mermaid
graph TD
    A[Manager calls setFeed] --> B[Validate feed parameters]
    B --> C[Check provider exists]
    C --> D[Set feed configuration]
    D --> E[Store TTL and provider ID]
    E --> F[Update feed mapping]
    F --> G[Emit FeedUpdated event]
```

**Function**: `OracleFacet.setFeed()`

**Parameters**:
```solidity
function setFeed(
    bytes32 _feed,        // Feed identifier (typically token address)
    address _provider,    // Provider implementation address
    bytes32 _providerId,  // Provider-specific identifier
    uint256 _ttl         // Time-to-live in seconds
)
```

### 2. Feed Removal

```mermaid
graph TD
    A[Manager calls removeFeed] --> B[Validate feed exists]
    B --> C[Remove feed mapping]
    C --> D[Clean provider reference]
    D --> E[Update storage]
    E --> F[Emit FeedRemoved event]
```

**Function**: `OracleFacet.removeFeed()`

### 3. Batch Feed Operations

```mermaid
graph TD
    A[Provider Update Required] --> B[Prepare feed arrays]
    B --> C[Call provider.setFeeds]
    C --> D[Validate all parameters]
    D --> E[Update all feeds atomically]
    E --> F[Emit batch events]
```

**Provider Function**: `OracleAdapter.setFeeds()`

## Alternative Provider Configuration

### 1. Fallback Setup

```mermaid
graph TD
    A[Manager calls setAlt] --> B[Validate alternative provider]
    B --> C[Check provider compatibility]
    C --> D[Set fallback mapping]
    D --> E[Update provider configuration]
```

**Function**: `OracleFacet.setAlt()`

**Fallback Logic**:
- Primary provider fails → Try alternative provider
- Alternative provider fails → Revert with stale price error
- Fallback providers must support same interface

### 2. Fallback Removal

```mermaid
graph TD
    A[Manager calls removeAlt] --> B[Validate provider exists]
    B --> C[Remove fallback mapping]
    C --> D[Update configuration]
```

**Function**: `OracleFacet.removeAlt()`

## Configuration Management

### 1. TWAP Lookback Configuration

```mermaid
graph TD
    A[Set Lookback Period] --> B{Global or Feed-Specific?}
    B -->|Global| C[setDefaultTwapLookback]
    B -->|Feed-Specific| D[setTwapLookback]
    C --> E[Update default configuration]
    D --> F[Update feed-specific config]
    E --> G[Apply to new feeds]
    F --> H[Override for specific feed]
```

**Functions**:
- `OracleFacet.setDefaultTwapLookback(uint32 _lookback)`
- `OracleFacet.setTwapLookback(bytes32 _feed, uint32 _lookback)`

### 2. Price Deviation Limits

```mermaid
graph TD
    A[Set Deviation Limits] --> B{Global or Feed-Specific?}
    B -->|Global| C[setDefaultMaxDeviation]
    B -->|Feed-Specific| D[setMaxDeviation]
    C --> E[Update default limits]
    D --> F[Update feed-specific limits]
    E --> G[Apply to price validation]
    F --> H[Override for specific feed]
```

**Functions**:
- `OracleFacet.setDefaultMaxDeviation(uint256 _maxDeviationBp)`
- `OracleFacet.setMaxDeviation(bytes32 _feed, uint256 _maxDeviationBp)`

## Provider Implementation Flows

### 1. Chainlink Provider Setup

```mermaid
graph TD
    A[Deploy ChainlinkProvider] --> B[Register with Oracle]
    B --> C[Configure feed mappings]
    C --> D[Set aggregator addresses]
    D --> E[Validate aggregator responses]
    E --> F[Set TTL periods]
    F --> G[Test price feeds]
```

**ChainlinkProvider Configuration**:
```solidity
struct ChainlinkParams {
    bytes32[] feeds;        // Asset identifiers
    bytes32[] providerIds;  // Aggregator addresses
    uint256[] ttls;        // Validity periods
}
```

### 2. Custom Provider Implementation

```mermaid
graph TD
    A[Extend PriceProvider] --> B[Implement _toUsdBp]
    B --> C[Override _setFeed]
    C --> D[Implement _update]
    D --> E[Add custom validation]
    E --> F[Deploy and register]
    F --> G[Configure feeds]
```

**Implementation Requirements**:
- Extend `PriceProvider` abstract contract
- Implement `_toUsdBp(address _asset, bool _invert)`
- Override feed management functions
- Provide update mechanism

## Price Query Operations

### 1. Basic Price Queries

```mermaid
graph TD
    A[Price Query Request] --> B{Query Type}
    B -->|USD Conversion| C[toUsd/fromUsd]
    B -->|Asset Conversion| D[convert]
    B -->|Exchange Rate| E[exchangeRate]
    C --> F[Provider._toUsdBp]
    D --> G[USD Intermediate Conversion]
    E --> H[Basis Point Calculation]
    F --> I[Return USD Amount]
    G --> J[Return Asset Amount]
    H --> K[Return Rate]
```

**Query Functions**:
- `toUsd(address _asset, uint256 _amount)`: Convert asset to USD
- `fromUsd(address _asset, uint256 _amount)`: Convert USD to asset
- `convert(address _base, address _quote, uint256 _amount)`: Direct conversion
- `exchangeRate(address _base, address _quote)`: Get exchange rate

### 2. Fallback Price Resolution

```mermaid
graph TD
    A[Primary Provider Query] --> B{Price Available?}
    B -->|Yes| C[Return Primary Price]
    B -->|No| D[Check Alternative Provider]
    D --> E{Alt Provider Available?}
    E -->|Yes| F[Query Alternative]
    E -->|No| G[Revert with StalePrice]
    F --> H{Alt Price Available?}
    H -->|Yes| I[Return Alternative Price]
    H -->|No| G
```

## Oracle Validation

### 1. Price Staleness Checks

```mermaid
graph TD
    A[Price Query] --> B[Get Last Update Time]
    B --> C[Calculate Age]
    C --> D{Age > TTL?}
    D -->|Yes| E[Try Fallback]
    D -->|No| F[Validate Price Range]
    E --> G{Fallback Available?}
    G -->|Yes| H[Query Fallback]
    G -->|No| I[Revert StalePrice]
    F --> J[Return Valid Price]
    H --> K[Validate Fallback Price]
    K --> L[Return Fallback Price]
```

### 2. Price Deviation Validation

```mermaid
graph TD
    A[New Price Available] --> B[Get Previous Price]
    B --> C[Calculate Deviation]
    C --> D{Deviation > Max?}
    D -->|Yes| E[Check Fallback]
    D -->|No| F[Accept Price]
    E --> G{Fallback Confirms?}
    G -->|Yes| H[Accept Price with Warning]
    G -->|No| I[Revert InvalidPrice]
    F --> J[Update Price History]
    H --> K[Log Deviation Event]
```

## Monitoring and Maintenance

### 1. Feed Health Monitoring

```mermaid
graph TD
    A[Monitor Feed Health] --> B[Check Last Update]
    B --> C[Validate Response Time]
    C --> D[Check Price Consistency]
    D --> E{Issues Detected?}
    E -->|Yes| F[Switch to Fallback]
    E -->|No| G[Continue Normal Operation]
    F --> H[Alert Managers]
    H --> I[Investigate Provider]
```

### 2. Provider Maintenance

```mermaid
graph TD
    A[Provider Update Required] --> B[Deploy New Version]
    B --> C[Test New Provider]
    C --> D[Update Provider Mapping]
    D --> E[Migrate Active Feeds]
    E --> F[Validate All Feeds]
    F --> G[Remove Old Provider]
```

## Error Handling

### Common Error Scenarios

1. **Stale Price**: TTL exceeded, no fallback available
2. **Invalid Price**: Negative or zero price from aggregator
3. **Static Call Failed**: Provider contract not responding
4. **Unexpected Output**: Malformed response from provider

### Recovery Procedures

1. **Feed Failure**: Switch to alternative provider
2. **Provider Failure**: Deploy new provider implementation
3. **Network Issues**: Increase TTL temporarily
4. **Invalid Data**: Remove problematic feed

## Access Control Matrix

| Operation | Admin | Manager | Keeper | Public |
|-----------|-------|---------|--------|--------|
| Initialize Oracle | ✓ | ✗ | ✗ | ✗ |
| Set Provider | ✗ | ✓ | ✗ | ✗ |
| Remove Provider | ✗ | ✓ | ✗ | ✗ |
| Set Feed | ✗ | ✓ | ✗ | ✗ |
| Remove Feed | ✗ | ✓ | ✗ | ✗ |
| Set Alternative | ✗ | ✓ | ✗ | ✗ |
| Configure TWAP | ✗ | ✓ | ✗ | ✗ |
| Set Deviation Limits | ✗ | ✓ | ✗ | ✗ |
| Query Prices | ✗ | ✗ | ✗ | ✓ |
| Check Feed Status | ✗ | ✗ | ✗ | ✓ |

## Integration Examples

### 1. Adding Chainlink Feed

```solidity
// 1. Deploy ChainlinkProvider (if not exists)
ChainlinkProvider provider = new ChainlinkProvider(diamond);

// 2. Register provider
oracleFacet.setProvider(address(provider), encodedParams);

// 3. Set feed for USDC
bytes32 usdcFeed = bytes32(uint256(uint160(USDC_ADDRESS)));
bytes32 aggregatorId = bytes32(uint256(uint160(USDC_CHAINLINK_AGGREGATOR)));
uint256 ttl = 3600; // 1 hour

oracleFacet.setFeed(usdcFeed, address(provider), aggregatorId, ttl);
```

### 2. Setting Up Fallback

```solidity
// Set Uniswap TWAP as fallback for Chainlink
oracleFacet.setAlt(chainlinkProvider, uniswapProvider);
```
This comprehensive oracle protocol flow documentation ensures proper understanding and implementation of all oracle management operations within the BTR protocol.

