# BTR Supply Contracts

<div align="center">
  <img border-radius="25px" max-height="250px" src="./banner.png" />
  <h1>BTR Supply: Market-Aware Automated Liquidity Manager</h1>
  <p>
    <strong>The first open and market-aware ALM for concentrated liquidity AMMs</strong>
  </p>
  <p>
    <a href="https://opensource.org/licenses/MIT"><img alt="License" src="https://img.shields.io/badge/license-MIT-000000?style=flat-square&logo=open-source-initiative&logoColor=white&labelColor=4c9c3d" width="auto"/></a>
    <a href="https://t.me/BTRSupply"><img alt="Telegram" src="https://img.shields.io/badge/Telegram-24b3e3?style=flat-square&logo=telegram&logoColor=white" width="auto"/></a>
    <a href="https://twitter.com/BTRSupply"><img alt="X (Twitter)" src="https://img.shields.io/badge/@BTRSupply-000000?style=flat-square&logo=x&logoColor=white" width="auto"/></a>
  </p>
</div>

---

## Table of Contents

- [Introduction](#introduction)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Introduction

**BTR** (Bayesian True Range), or simply 'Better', is the first open and market-aware Automated Liquidity Manager (ALM) designed for concentrated liquidity AMMs like Uniswap V3/V4, PancakeSwap V3, Thena, and other Algebra DEX deployments.

BTR consists of two interconnected systems:

### BTR Markets (Data Layer)
A transparent, high-frequency data aggregator that tracks prices, volumes, and depth across 50+ centralized exchanges and 1000+ liquidity pools across multiple chains. It provides:
- Open statistical estimators for trend, volatility, and momentum
- Unbiased and transparent aggregation methodology
- Adaptive range optimization models that work across all asset pairs

### BTR Supply (On-Chain ALM)
This repository contains the smart contract implementation that utilizes insights from BTR Markets to execute adaptive, transparent market-making strategies. Key innovations include:

- **Predictive Range Optimization**: Liquidity ranges determined by market-specific algorithms trained on high-fidelity data
- **MEV Protection**: Swaps and operations shielded through timing randomization and protected relays
- **DEX-Agnostic Vaults**: Single vaults manage positions across multiple compatible DEXs simultaneously
- **Gas-Efficient ERC-1155 Design**: Vaults implemented as token instances rather than standalone contracts

## Key Features

### 🎯 **Market-Aware Strategy**
- Real-time market data integration from BTR Markets
- Adaptive range sizing based on volatility and momentum
- Cross-DEX arbitrage and rebalancing

### ⚡ **Gas-Optimized Operations**
- Cash buffer system for instant deposits/withdrawals
- Batch rebalancing to socialize gas costs
- ERC-1155 vault shares for reduced deployment overhead

### 🛡️ **MEV Protection**
- Protected swap routing through aggregators
- Non-deterministic execution timing
- Slippage protection and circuit breakers

### 🔄 **Multi-DEX Support**
- Uniswap V3/V4 compatibility + forks (eg. PancakeSwap V3/V4)
- Algebra DEX support (eg. Thena, Camelot, QuickSwap)
- Unified liquidity management across protocols

### 💰 **Fair Fee Model**
- Negligible entry/exit fees
- Performance and management fee structures
- Treasury fee collection and distribution

## Architecture Overview

BTR Supply uses the **Diamond Standard (EIP-2535)** for modularity and safe upgradability,
and standalone adapters for DEX and oracle adapters. Core components include:

### Technical Facets
- **DiamondLoupe**: Provides introspection capabilities for the diamond
- **DiamondCut**: Handles upgrades and facet management

### ALM Facets
- **ALMUser**: User-facing deposit/withdrawal operations
- **ALMProtected**: Admin/keeper operations (rebalancing, vault management)
- **ALMInfo**: Read-only vault information and previews

### Protocol Facets
- **AccessControl**: Role-based permissions
- **RiskModel**: Risk assessment and management
- **Treasury**: Fee collection and management
- **Management**: Protocol configuration
- **Rescue**: Emergency recovery operations

### Information Facets
- **Oracle**: External price feeds and data integration
- **Info**: General information retrieval
- **ALMInfo**: Read-only vault information and previews

### DEX Adapters
#### Ticks Based
- **V3Adapter**: Base for Uniswap V3-style integrations
- **UniV3Adapter**: Uniswap V3 integration
- **UniV4Adapter**: Uniswap V4 integration
- **CakeV3Adapter**: PancakeSwap V3 integration (Uniswap V3 based)
- **CakeV4Adapter**: PancakeSwap V4 integration (Uniswap V4 based)
- **VeloV3Adapter**: Velodrome Slipstream integration (Solidly/Uniswap V3 based)
- **AeroV3Adapter**: Aerodrome Slipstream integration (Velodrome Slipstream based)
- **KodiakV3Adapter**: Kodiak V3 integration (Uniswap V3 based)
- **AgniV3Adapter**: Agni V3 integration (Uniswap V3 based)
- **SailorV3Adapter**: Sailor V3 integration (Uniswap V3 based)
- **KyoV3Adapter**: Kyo V3 integration (Uniswap V3 based)
- **SonexV3Adapter**: Sonex V3 integration (Uniswap V3 based)
- **HyperSwapV3Adapter**: HyperSwap V3 integration (Uniswap V3 based)
- **ThrusterV3Adapter**: Thruster V3 integration (Uniswap V3 based)
- **EqualizerV3Adapter**: Equalizer V3 integration (Solidly/Uniswap V3 based)
- **RamsesV3Adapter**: Ramses V3 integration (Solidly/Uniswap V3 based)
- **PharaohV3Adapter**: Pharaoh V3 integration (Ramses V3 based)
- **ShadowV3Adapter**: Shadow V3 integration (Ramses V3 based)
- **ThenaV3Adapter**: Thena V3 Fusion integration (Solidly/Algebra V4 based)
- **CamelotV3Adapter**: Camelot V3 integration (Algebra based)
- **QuickV3Adapter**: QuickSwap V3 integration (Algebra V3 based)
- **LynexV3Adapter**: Lynex V3 Adapter (Solidly/Algebra V3 based)
- **SwapXV4Adapter**: SwapX V3 Adapter (Algebra V4 based)
- **StellaSwapV4Adapter**: StellaSwap V4 Adapter (Algebra V4 based)

#### Buckets Based
- **JoeV2Adapter**: Joe V2(.*) integration
- **MoeAdapter**: Merchant Moe integration (Joe V2 based)
- **MetropolisAdapter**: Metropolis integration (Joe V2 based)

For detailed architecture information, see [`docs/architecture.md`](./docs/architecture.md).

## Getting Started

### Prerequisites
- **Foundry**: [Installation Guide](https://book.getfoundry.sh/getting-started/installation)
- **Python** >= 3.10
- **uv**: [Installation Guide](https://github.com/astral-sh/uv#installation)

### Installation

1. **Clone and setup:**
   ```bash
   git clone <repository_url>
   cd contracts
   make install-deps
   ```

2. **Configure environment:**
   ```bash
   cp evm/.env.example evm/.env
   # Edit evm/.env with your values
   ```

3. **Build contracts:**
   ```bash
   make build
   ```

4. **Run tests:**
   ```bash
   make test
   ```

## Development Workflow

### Code Quality
```bash
make format          # Format all code
make python-lint-fix # Fix Python linting issues
```

### Testing
```bash
make test           # Run full test suite
```

### Releasing
```bash
make publish-patch  # Patch version (0.1.0 -> 0.1.1)
make publish-minor  # Minor version (0.1.1 -> 0.2.0)  
make publish-major  # Major version (0.2.0 -> 1.0.0)
```

### Build Process
The project uses a three-step compilation process via `./scripts/build.sh`:
1. Compile facets from `./evm/src/facets`
2. Generate diamond deployment script
3. Compile all components together

## Testing

The test suite covers:

- **Unit Tests**: Individual component testing in [`evm/tests/unit`](./evm/tests/unit)
- **Integration Tests**: Full workflow testing in [`evm/tests/integration`](./evm/tests/integration)
- **Fork Tests**: Mainnet fork testing for realistic scenarios

Tests use the `BaseALMTest` abstraction for common ALM functionality with specific implementations for each DEX adapter.

See [`docs/testing.md`](./docs/testing.md) for detailed testing strategy.

## Documentation

Comprehensive documentation is available in the [`docs/`](./docs) directory:

- **[Architecture](./docs/architecture.md)**: System design and component overview
- **[User Flows](./docs/alm/user-flows.md)**: Deposit/withdrawal mechanics and fee structures
- **[Protocol Flows](./docs/alm/protocol-flows.md)**: Admin operations and rebalancing
- **[Vault Allocation](./docs/vault-allocation.md)**: Risk-based allocation methodology
- **[Liquidity Management](./docs/liquidity-requirements.md)**: Buffer system and liquidity optimization
- **[Testing Guide](./docs/testing.md)**: Testing strategy and implementation

## Contributing

Please follow the development guidelines in the project configuration:

1. **Code Style**: Use `make format` before committing
2. **Testing**: Ensure all tests pass with `make test`
3. **Commit Messages**: Follow conventional commit format for automated changelog generation
4. **Pull Requests**: Include comprehensive test coverage for new features

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## Inspiration and Acknowledgments

BTR Supply draws inspiration from pioneering ALM solutions including Arrakis Finance, Gamma Strategies, Steer Protocol, Beefy CLM, Ichi, Maverick Protocol, and Kamino Liquidity, while introducing novel market-awareness and cross-DEX capabilities.
