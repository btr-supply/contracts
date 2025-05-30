# BTR Supply DEX Integrations

BTR Supply provides a unified liquidity management interface across multiple decentralized exchanges (DEXs) through specialized adapter contracts. This document outlines current integrations and planned expansions.

## Overview

BTR Supply's adapter architecture enables seamless liquidity management across different AMM protocols while maintaining a consistent interface. Each adapter handles protocol-specific logic for:

- Position creation and management
- Liquidity provision and withdrawal
- Fee collection and compounding
- Cross-DEX arbitrage and rebalancing

## Current Integrations

### EVM Chains

BTR Supply currently supports EVM-compatible chains through two main categories of AMM integrations:

#### Ticks-Based AMMs

These adapters work with concentrated liquidity AMMs that use tick-based price ranges, primarily based on Uniswap V3 and Algebra architectures.

##### Uniswap V3/V4 & Forks

- **V3TickAdapter**: Base implementation for Uniswap V3-style tick-based integrations
- **V4TickAdapter**: Base implementation for Uniswap V4-style tick-based integrations
- **UniV3Adapter**: Uniswap V3 integration
- **UniV4Adapter**: Uniswap V4 integration
- **CakeV3Adapter**: PancakeSwap V3 integration (Uniswap V3 based)
- **CakeV4Adapter**: PancakeSwap V4 integration (Uniswap V4 based)
- **SolidlyV3Adapter**: Solidly V3 integration (Uniswap V3)
- **KodiakV3Adapter**: Kodiak V3 integration (Uniswap V3 based)
- **AgniV3Adapter**: Agni V3 integration (Uniswap V3 based)
- **SailorV3Adapter**: Sailor V3 integration (Uniswap V3 based)
- **KyoV3Adapter**: Kyo V3 integration (Uniswap V3 based)
- **SonexV3Adapter**: Sonex V3 integration (Uniswap V3 based)
- **HyperSwapV3Adapter**: HyperSwap V3 integration (Uniswap V3 based)
- **ThrusterV3Adapter**: Thruster V3 integration (Uniswap V3 based)
- **VeloV3Adapter**: Velodrome Slipstream integration (Solidly/Uniswap V3 based)
- **AeroV3Adapter**: Aerodrome Slipstream integration (Velodrome Slipstream based)
- **EqualizerV3Adapter**: Equalizer V3 integration (Solidly/Uniswap V3 based)
- **RamsesV3Adapter**: Ramses V3 integration (Solidly/Uniswap V3 based)
- **PharaohV3Adapter**: Pharaoh V3 integration (Ramses V3 based)
- **ShadowV3Adapter**: Shadow V3 integration (Ramses V3 based)

##### Algebra V3/V4 Deployments
- **AlgebraV3Adapter**: Base implementation for Algebra DEX (V3) deployments
- **AlgebraV4Adapter**: Base implementation for Algebra Integral (V4) deployments
- **ThenaV3Adapter**: Thena V3 Fusion integration (Solidly/Algebra V4 based)
- **CamelotV3Adapter**: Camelot V3 integration (Algebra based)
- **QuickV3Adapter**: QuickSwap V3 integration (Algebra V3 based)
- **LynexV3Adapter**: Lynex V3 Adapter (Solidly/Algebra V3 based)
- **SwapXV4Adapter**: SwapX V3 Adapter (Algebra V4 based)
- **StellaSwapV4Adapter**: StellaSwap V4 Adapter (Algebra V4 based)

#### Buckets-Based AMMs

These adapters work with AMMs that use discrete liquidity buckets instead of continuous tick ranges.

##### Joe V2 & Forks

- **V2BucketAdapter**: Joe V2-style bucket-based integration
- **JoeV2Adapter**: Joe V2(.x) integration
- **MoeV2Adapter**: Merchant Moe V2 integration (Joe V2 based)
- **MetropolisV2Adapter**: Metropolis V2 integration (Joe V2 based)

## Roadmap

### SVM Chains (Solana)

BTR Supply plans to expand to Solana Virtual Machine (SVM) compatible chains, supporting major Solana AMM protocols:

#### Planned SVM Integrations

- **Raydium CLMM**: Tick-based concentrated liquidity market maker
- **Orca**: Tick-based concentrated liquidity protocol
- **Meteora**: Liquidity bucket-based AMM

These integrations will enable cross-chain liquidity management and arbitrage opportunities between EVM and SVM ecosystems.

## Architecture Benefits

### Unified Interface
- Consistent API across all DEX integrations
- Simplified vault management regardless of underlying protocol
- Standardized fee collection and position tracking

### Cross-DEX Capabilities
- Single vault can manage positions across multiple compatible DEXs
- Automatic arbitrage between integrated protocols
- Optimized gas usage through batch operations

### Modularity
- Easy addition of new DEX integrations
- Protocol-specific optimizations without affecting core logic
- Independent upgrade paths for each adapter

## Integration Requirements

Each new DEX adapter must implement:

1. **Position Management**: Create, modify, and close liquidity positions
2. **Asset Handling**: Deposit, withdraw, and swap tokens
3. **Fee Collection**: Harvest and compound protocol fees
4. **Price Discovery**: Retrieve current pool prices and tick information
5. **Slippage Protection**: Implement appropriate slippage safeguards

For detailed integration specifications, see the adapter development guide in the developer documentation.
