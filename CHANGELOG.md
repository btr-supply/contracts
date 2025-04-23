# BTR Contracts Changelog

All changes documented here, based on [Keep a Changelog](https://keepachangelog.com).
See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

NB: [Auto-generated from commits](./scripts/release.py) - DO NOT EDIT.


## [0.3.0] - 2025-04-23

### Features
- [feat] Add integration tests for BTR swap functionality

### Refactors
- [refac] Install pre-commit hooks, replace header script
- [refac] Migrate header formatting from shell script to Python implementation
- [refac] Move CakeV3 interfaces to dexs/ and update desc.yml
- [refac] Remove redundant comments in Managed.sol
- [refac] Standardize Solidity file formatting and headers across all contracts

### Ops
- [ops] Generalize format-headers.sh to process all desc.yml files
- [ops] Move get-swap-data.sh script to shared scripts directory

### Docs
- [docs] Clarify commit guidelines in Development Workflow


## [0.2.0] - 2025-04-19

### Features
- [feat] AccessControl + Rescue tested
- [feat] BTR token testing + Treasury initializer + Diamond deployer generator + cursorrules update
- [feat] Create3 deployment + salt minting
- [feat] Implemented xERC20 BTR + LZ adapter base
- [feat] Management + Treasury libs and facets tests
- [feat] Testing facets deployments

### Refactors
- [refac] Apply formatting and minor refactoring to EVM contracts
- [refac] Cleanup/refacto
- [refac] Interfaces update + cleanup
- [refac] Overhaul build system and deployment scripts
- [refac] Refactor deployer generation script and logic
- [refac] Refactor EVM tests, introduce BaseDiamondTest and integration tests

### Ops
- [ops] Add project metadata, license, changelog, and utility scripts
- [ops] Add scripts and Makefile targets for branch/commit validation
- [ops] Automate commit and tag steps in release targets
- [ops] Configure pre-commit hooks for automated checks
- [ops] Configure pre-commit, formatting, and linting tools
- [ops] Extract release commit/tag logic to release.sh
- [ops] Forge init+config
- [ops] Improve script reliability and release process
- [ops] Release v0.2.0
- [ops] Replace Black with Yapf for Python formatting
- [ops] Setup.sh update + DiamondDeployer generation with facets.json desc file + all technical facets tested
- [ops] Simplify release.sh script

### Docs
- [docs] Update CONTRIBUTING.md for current structure and tooling
