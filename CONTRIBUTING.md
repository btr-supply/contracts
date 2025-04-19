# Contributing to BTR Supply Contracts

Thank you for your interest in contributing to BTR Supply Contracts! This document provides guidelines for contributing to the project. All participants are expected to be respectful and inclusive in all interactions. Harassment of any kind is not tolerated.

## Table of Contents

- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Branch Structure](#branch-structure)
- [Naming Conventions](#naming-conventions)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Release Process](#release-process)

## Project Structure

This project manages smart contracts across multiple blockchains:

- **`./evm`**: Solidity smart contracts for EVM-compatible chains, managed using Foundry.
- **`./solana`**: Rust programs for the Solana blockchain.
- **`./sui`**: Move packages for the Sui blockchain.
- **`./scripts`**: Shared scripts (Bash, Python) for building, testing, formatting, and deployment.

## Getting Started

### Prerequisites

- **Unix-like system**: macOS or Linux recommended. WSL (Windows Subsystem for Linux) might work but is untested.
- **[Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)**: Version control.
- **[Python](https://www.python.org/downloads/)**: >= 3.9 for scripting and tooling.
- **[uv](https://github.com/astral-sh/uv)**: Python package installer and resolver.
- **[Foundry](https://book.getfoundry.sh/getting-started/installation)**: For EVM development (`forge`, `cast`).
- **[Solana Tool Suite](https://docs.solana.com/cli/install)** & **[Anchor](https://www.anchor-lang.com/docs/installation)**: Required if working within `./solana`.
- **[Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install)**: Required if working within `./sui`.

### Setup steps

1.  **Fork the repository** to your GitHub account.
2.  **Clone your fork** locally:
    ```bash
    # Replace <your-username> with your actual GitHub username
    git clone https://github.com/<your-username>/contracts.git
    cd contracts
    ```
3.  **Install dependencies**: This installs Python tools via `uv` and potentially other system dependencies needed for the different chains (like Foundry).
    ```bash
    make install-deps
    ```
    *(Note: You might need to manually install Solana/Sui toolchains if not handled by the script).*

## Development Workflow

We follow a simplified version of the widely popular [gitflow](https://danielkummer.github.io/git-flow-cheatsheet/):

```
main     ← production-ready, version bumps + releases triggered via Make commands
└── dev  ← active development (features, fixes merged here)
    └── feat/fancy-stuff
    └── fix/bug-123
```

1.  Create a new branch from `dev` with the appropriate prefix (see [Naming Conventions](#naming-conventions)).
2.  Make your changes.
3.  Ensure code quality and build success by running `make build`. This typically includes formatting, linting, and compiling contracts.
4.  Commit your changes with a properly formatted commit message (see [Naming Conventions](#naming-conventions)).
5.  Create a pull request to merge your changes into the `dev` branch.
6.  After review and approval, your changes will be merged into `dev`.
7.  Periodically, the `dev` branch is merged (linearly) into `main` for releases using the `make release-*` commands.

## Branch Structure

-   **`main`** - Production branch
    -   Contains stable, released code.
    -   Releases are tagged and created from this branch using `make release-*` commands.
-   **`dev`** - Development branch
    -   Active development happens here.
    -   Features and fixes are merged into this branch via Pull Requests.
    -   Periodically merged into `main` for releases.
-   **Feature/Fix branches** - Created from `dev`
    -   Follow naming conventions (e.g., `feat/add-new-facet`, `fix/solana-build`).
    -   Always merge back into `dev`.

## Naming Conventions

### Branch and Commit Format

All branches and commits must use specific prefixes for consistency:

| Type    | Description                 | Branch Example        | Commit Example                         |
| ------- | --------------------------- | --------------------- | -------------------------------------- |
| **feat**  | New features, improvements  | `feat/evm-permit2`    | `[feat] Add Permit2 support to EVM`    |
| **fix**   | Bug fixes, typos            | `fix/sui-build-error` | `[fix] Resolve Sui package build issue`|
| **refac** | Code style, performance     | `refac/python-script` | `[refac] Optimize deployment script`   |
| **ops**   | Tooling, scripting, CI/CD   | `ops/update-makefile` | `[ops] Add new target to Makefile`     |
| **docs**  | Documentation, READMEs      | `docs/solana-usage`   | `[docs] Explain Solana program usage`  |
| **chore** | Minor non-functional change | `chore/bump-uv`       | `[chore] Update uv version`            |

#### Important Notes:

-   Commit message subjects should be capitalized.
-   Branch names must start with the type prefix followed by `/`.
-   Commit messages must start with the type in square brackets `[]`.
-   While not strictly enforced by hooks currently, adhering to these conventions is expected.

## Pull Request Process

1.  Ensure `make build` and `make test` pass locally.
2.  The pull request title should follow the commit format (e.g., `[feat] Add awesome feature`).
3.  Reference related issues in your PR description (e.g., "Closes #123").
4.  Wait for review from a project maintainer. Address any feedback provided.

## Coding Standards

We enforce coding standards through configuration files and `make` commands:

-   **General**: `.editorconfig` defines basic settings like indentation (2 spaces) and line endings.
-   **Python**:
    -   Formatting: `yapf` enforces style. Run `make format` (which executes `scripts/format-code.sh`). Configuration is in `.style.yapf`.
    -   Linting: `ruff` checks for errors and style issues. Run `make python-lint-fix` or `make build`. Configuration is in `pyproject.toml`.
-   **Solidity (EVM)**:
    -   Formatting: `forge fmt` enforces style. Run `make format` (which executes `scripts/format-code.sh`). Configuration is in `foundry.toml`.
-   **Solana (Rust)**:
    -   Formatting: Use `cargo fmt` within the `./solana` directory.
    -   Linting: Use `cargo clippy` within the `./solana` directory.
-   **Sui (Move)**:
    -   Formatting: Use `sui move fmt` within the relevant package directory in `./sui`.
    -   Linting: Use `sui move lint` (if applicable/available).
-   **Pre-commit Checks**: Before committing, it's recommended to run `make build` to catch formatting, linting, and compilation errors early.

## Testing

Contract and script changes should include appropriate tests:

-   Run all available tests:
    ```bash
    make test
    ```
-   This command typically executes:
    -   EVM tests using `forge test` (tests found in `./evm/tests`).
    -   Solana tests using `anchor test` (tests found in `./solana/tests`).
    -   Sui tests using `sui move test` (tests found in `./sui/tests`).

## Release Process

This project follows [Semantic Versioning](https://semver.org/). Releases are managed via `make` targets which utilize `scripts/release.py`.

1.  **Prepare**: Ensure `dev` is stable and all desired changes are merged. Update `CHANGELOG.md` under the "Unreleased" section.
2.  **Release** (for maintainers): From the `main` branch, run the appropriate command:
    ```bash
    # For a patch release (e.g., 0.1.0 -> 0.1.1)
    make release-patch

    # For a minor release (e.g., 0.1.1 -> 0.2.0)
    make release-minor

    # For a major release (e.g., 0.2.0 -> 1.0.0)
    make release-major
    ```
3.  **Automation**: The script updates `pyproject.toml`, updates `CHANGELOG.md`, creates a commit, tags the commit, and pushes the changes and tag. GitHub Actions (if configured) might create a GitHub Release based on the tag.
