<div align="center">
  <img border-radius="25px" max-height="250px" src="./banner.png" /> <!-- Assuming banner exists at this path -->
  <h1>BTR Supply Contracts</h1>
  <p>
    <strong>Concentrated Liquidity Position Manager</strong>
  </p>
  <p>
    <!-- Placeholder for relevant badge, e.g., build status if available -->
    <!-- <a href="https://btr.supply/docs"><img alt="Docs" src="https://img.shields.io/badge/Docs-212121?style=flat-square&logo=readthedocs&logoColor=white" width="auto"/></a> -->
    <a href="https://opensource.org/licenses/MIT"><img alt="License" src="https://img.shields.io/badge/license-MIT-000000?style=flat-square&logo=open-source-initiative&logoColor=white&labelColor=4c9c3d" width="auto"/></a>
    <a href="https://t.me/BTRSupply"><img alt="Telegram" src="https://img.shields.io/badge/Telegram-24b3e3?style=flat-square&logo=telegram&logoColor=white" width="auto"/></a>
    <a href="https://twitter.com/BTRSupply"><img alt="X (Twitter)" src="https://img.shields.io/badge/@BTRSupply-000000?style=flat-square&logo=x&logoColor=white" width="auto"/></a>
    </p>
</div>

---

## Table of Contents

- [Introduction](#introduction)
- [Key Features & Innovations](#key-features--innovations)
- [Repository Overview](#repository-overview)
- [EVM Architecture (Diamond Standard)](#evm-architecture-diamond-standard)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Releasing](#releasing)
- [Key Scripts](#key-scripts)
- [Contributing](#contributing)
- [Project Evolution & Inspirations](#project-evolution--inspirations)
- [License](#license)

## Introduction

**BTR** (Bayesian True Range), or simply 'Better', is the first open and market-aware Automated Liquidity Manager (ALM) designed for concentrated liquidity AMMs like Uniswap V3/V4, Algebra DEX, Raydium, Orca, and more.

Concentrated Liquidity AMMs offer superior capital efficiency but require active management, similar to traditional market-making. Existing ALM solutions often fall short due to:

*   Lagging market data and overlooked volatility.
*   Inefficient or opaque rebalancing strategies.
*   Lack of true market awareness beyond a single pool.
*   Complex user experiences.

BTR aims to solve these issues through a two-part system:

1.  **BTR Markets (Data Layer):** A transparent, high-frequency data aggregator tracking prices, volumes, and depth across numerous CEXs and DEXs. It provides open statistical estimators for trend, volatility, and momentum.
2.  **BTR Supply (On-Chain ALM):** The smart contract layer that utilizes insights from BTR Markets to execute an adaptive, transparent market-making strategy. It focuses on providing robust, auto-compounding vaults with a simplified user experience across multiple blockchains.

This repository contains the smart contracts for **BTR Supply**.

## Key Features & Innovations

BTR Supply incorporates several unique features designed to maximize efficiency and yield:

*   **Predictive Range Optimization:** Liquidity ranges are determined by a perpetually optimized, market-specific predictive algorithm trained on high-fidelity tick and depth data from BTR Markets. The precise triggering rules for rebalancing remain off-chain for strategic reasons but are designed for future verifiability by liquidity providers.
*   **MEV Protection:** All protocol swaps and upkeep operations are shielded from MEV (Maximal Extractable Value) through techniques like pseudo-random execution timing, non-deterministic rule application, and the use of MEV-protecting relays/RPC nodes.
*   **Swapping via BTR Swap:** All swaps leverage [BTR Swap's aggregator](https://github.com/btr-supply/btr-swap), which routes orders across DEXs, and RFQ/intent-based systems to guarantee minimal slippage and fees, directly enhancing LP returns. Historical swapping performance data will be publicly available for audit.
*   **DEX-Agnostic Vaults:** BTR Vaults operate across multiple compatible DEXs simultaneously. For instance, a single USDC-USDT vault on BNB Chain can manage liquidity positions across Uniswap V3, Uniswap V4, PancakeSwap V3, and Thena pools for that pair, automatically arbitraging and rebalancing liquidity between them. This significantly simplifies the user experience, as LPs deposit into a single vault per pair per chain.
*   **Gas-Efficient ERC-1155 Vaults:** Vaults are implemented as ERC-1155 token instances rather than standalone contracts (similar to Uniswap V4 pools). This minimizes deployment overhead and reduces operational gas costs for actions like deposits, withdrawals, and rebalancing.

## Repository Overview

This repository houses the smart contract implementations for the BTR Supply ALM system, targeting:

*   **EVM Chains:** Primarily developed using Foundry ([`./evm`](./evm)).
*   **Solana:** Code located in [`./solana`](./solana).
*   **Sui:** Code located in [`./sui`](./sui).

Key top-level directories:
*   [`./scripts`](./scripts): Project-wide scripts for tasks like releasing, formatting, and utility functions.
*   [`./assets`](./assets): Contains project metadata, descriptions ([`desc.yml`](./assets/desc.yml)), and potentially other assets like images.

## EVM Architecture (Diamond Standard)

The EVM implementation utilizes the **Diamond Standard (EIP-2535)** for modularity, upgradability, and gas efficiency. The core diamond proxy is implemented in [`./evm/src/BTRDiamond.sol`](./evm/src/BTRDiamond.sol).

Key components within `./evm/src`:

*   **Facets ([`./facets`](./evm/src/facets)):** Individual units of logic plugged into the diamond. Examples include:
    *   `ALMFacet.sol`: Core Automated Liquidity Management logic (position calculation, rebalancing).
    *   `ERC1155VaultsFacet.sol`: Manages LP positions represented as ERC1155 tokens.
    *   `DEXAdapterFacet.sol` (and specific implementations like `UniV3AdapterFacet.sol`, `CakeV3AdapterFacet.sol`): Interfaces with different DEX protocols.
    *   `SwapperFacet.sol`: Handles token swaps via registered DEX adapters.
    *   `ManagementFacet.sol`: Protocol parameter management (e.g., pausing).
    *   `AccessControlFacet.sol`: Role-based access control.
    *   `DiamondCutFacet.sol` / `DiamondLoupeFacet.sol`: Standard diamond upgrade and introspection logic.
    *   *(Refer to [`assets/desc.yml`](./assets/desc.yml) for a full list and descriptions)*
*   **Libraries ([`./libraries`](./evm/src/libraries)):** Reusable code modules used by facets. Examples include:
    *   `LibALM.sol`: Core ALM calculations.
    *   `LibDEXMaths.sol`: DEX-specific math (tick calculations, price conversions).
    *   `LibDiamond.sol`: Diamond storage interaction helpers.
    *   `BTRStorage.sol`: Defines the diamond's storage layout (AppStorage pattern).
    *   *(Refer to [`assets/desc.yml`](./assets/desc.yml) for a full list and descriptions)*
*   **Scripts ([`../scripts`](./evm/scripts)):** Foundry scripts for deployment and contract interaction ([`DeployDiamond.s.sol`](./evm/scripts/DeployDiamond.s.sol), etc.).
*   **Tests ([`../tests`](./evm/tests)):** Unit and integration tests.

## Getting Started

### Prerequisites

*   **Git:** [Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
*   **Foundry:** [Installation Guide](https://book.getfoundry.sh/getting-started/installation) (Installs `forge`, `cast`, `anvil`)
*   **Python:** >= 3.10 recommended.
*   **uv:** Fast Python package installer/resolver. [Installation Guide](https://github.com/astral-sh/uv#installation)
*   **pre-commit:** Git hook manager. [Installation Guide](https://pre-commit.com/#install)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd contracts # Or your cloned directory name
    ```

2.  **Install dependencies and setup hooks:**
    ```bash
    make install-deps
    ```
    This command will:
    *   Run `scripts/install_deps.sh` to ensure necessary system dependencies are present.
    *   Use `uv sync` to create a virtual environment (if needed) and install Python packages listed in [`pyproject.toml`](./pyproject.toml).
    *   Install git hooks using `pre-commit` for automated formatting, linting, and commit checks.

### Environment Configuration

Certain operations, particularly integration tests involving chain forks or deployments, require environment variables (e.g., RPC URLs, private keys).

*   Copy the example environment file:
    ```bash
    cp evm/.env.example evm/.env
    ```
*   Edit [`evm/.env`](./evm/.env) and populate it with your specific values. **Never commit your `.env` file.**

## Development Workflow

### Formatting

Ensure code conforms to project standards:

```bash
make format
```
This runs `forge fmt` for Solidity and custom formatters ([`scripts/format_code.sh`](./scripts/format_code.sh), [`scripts/format_headers.py`](./scripts/format_headers.py)).

### Linting

Check and fix Python code style using Ruff:

```bash
make python-lint-fix
```

### Git Hooks (Pre-commit)

The `pre-commit` hooks installed via `make install-deps` automatically run checks before certain git actions. The configured hooks include:
*   **pre-commit:** Runs formatters (`forge fmt`, custom scripts) and linters (`ruff`).
*   **commit-msg:** Validates commit message format using [`scripts/check_name.py -c`](./scripts/check_name.py).
*   **pre-push:** Validates branch name and commit messages before pushing using [`scripts/check_name.py -p`](./scripts/check_name.py).
*   **post-checkout:** Can be used for environment synchronization after switching branches.

These ensure code quality and consistency.

## Testing

Run the test suite using Foundry:

```bash
make test
```
This command typically executes [`scripts/test.sh`](./scripts/test.sh), which runs `forge test`.

*   **Unit Tests:** Located in [`evm/tests/unit`](./evm/tests/unit), focusing on isolated contract logic.
*   **Integration Tests:** Located in [`evm/tests/integration`](./evm/tests/integration), verifying interactions between facets and external contracts, often using mainnet forks (configured via [`evm/.env`](./evm/.env)). See [`evm/tests/integration/spec.md`](./evm/tests/integration/spec.md) for detailed test scenarios.

## Releasing

The release process is automated using Make commands:

```bash
# For a new patch version (e.g., 0.1.0 -> 0.1.1)
make publish-patch

# For a new minor version (e.g., 0.1.1 -> 0.2.0)
make publish-minor

# For a new major version (e.g., 0.2.0 -> 1.0.0)
make publish-major
```

These commands execute [`scripts/release.sh`](./scripts/release.sh), which in turn runs [`scripts/release.py`](./scripts/release.py). The process involves:

1.  Checking if the current branch is `main`.
2.  Calculating the next version number.
3.  Updating the version in [`pyproject.toml`](./pyproject.toml).
4.  Generating/updating [`CHANGELOG.md`](./CHANGELOG.md) based on commit messages since the last tag (using prefixes like `[feat]`, `[fix]`, `[refac]`, etc.).
5.  Committing the version bump and changelog changes (`[ops] Release vX.Y.Z`).
6.  Creating a Git tag (`vX.Y.Z`).
7.  Pushing the commit and tag to the `origin` remote.

Make sure your commit messages follow the convention expected by [`scripts/release.py`](./scripts/release.py) (see `COMMIT_PREFIX_MAP` in the script) for accurate changelog generation.

## Key Scripts

Beyond testing and releasing, several utility scripts exist in [`./scripts`](./scripts):

*   [`generate_deployer.py`](./scripts/generate_deployer.py): Generates the [`DiamondDeployer.gen.sol`](./evm/utils/generated/DiamondDeployer.gen.sol) contract used in deployment scripts based on [`facets.json`](./scripts/facets.json).
*   [`get_swap_data.sh`](./scripts/get_swap_data.sh): Example script demonstrating how to use an external `btr-swap` tool to fetch optimal swap data from aggregators.
*   [`check_name.py`](./scripts/check_name.py): Validates branch names and commit messages (used by pre-commit hooks).
*   [`format_code.sh`](./scripts/format_code.sh) / [`format_headers.py`](./scripts/format_headers.py): Code formatting utilities.


## Project Evolution & Inspirations

BTR Supply originated as a fork of [Arrakis V2](https://github.com/ArrakisFinance/v2-core), subsequently extended to support a wider range of DEXs including Uniswap V3 forks and Algebra DEX deployments. Over time, it has evolved into a largely re-implemented, optimized, and more comprehensive liquidity management solution.

While now distinct, BTR Supply draws inspiration from pioneering work in the ALM space, including:

*   [Arrakis Finance (V2 & V3/Modular)](https://arrakis.finance/)
*   [Maverick Protocol](https://www.mav.xyz/)
*   [Steer Protocol](https://app.steer.finance/)
*   [Kamino Liquidity](https://kamino.finance)

## Contributing

Please follow standard development practices: lint code, ensure tests pass, and adhere to commit message conventions for automated changelog generation. Refer to the project's contribution guidelines in [`./CONTRIBUTING.md`](./CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License - see the [`./LICENSE`](./LICENSE) file for details.
