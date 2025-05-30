# ALM Protocol Testing Strategy

This document outlines the comprehensive testing strategy for the BTR protocol's Automated Liquidity Management (ALM) infrastructure. It covers test targets, environment setup, structure, requirements, implementation plans, review processes, and additional testing considerations.

## Test Coverage Targets
Implementations will appear in:
- `CakeV3StableALMTest.t.sol` (for PancakeSwap V3)
- `ThenaV3StableALMTest.t.sol` (for Thena V3)
- `UniV3StableALMTest.t.sol` (for Uniswap V3)

All tests inherit from the abstract `BaseALMTest.t.sol` which provides common ALM testing infrastructure.

## Environment Setup
- Testing operates on BNB Chain forks using the RPC URL in `.env` variable: `HTTPS_RPC_56`
- Diamond deployment and facet setup is handled through `BaseDiamondTest.t.sol`
- Build commands defined in `scripts/setup.sh` compile contracts and generate deployment scripts

## Test Structure and Requirements

### Core Test Abstractions
1. **BaseDiamondTest.t.sol**: Handles diamond deployment with all core facets correctly initialized.
2. **BaseALMTest.t.sol**: Sets up ALM environment, declaring virtual methods to be overridden:
   - `weights()` - Position weight distribution
   - `ranges()` - Tick boundaries for positions
   - `getToken0()`, `getToken1()` - Fetch test tokens
   - `pools()` - Return test pool addresses

### Test Implementation Requirements
Each DEX adapter test should implement full lifecycle tests:

1. **Setup and Initialization**
   - Deploy adapter facets for specific DEX (CakeV3, ThenaV3, UniV3)
   - Register pool info with actual mainnet pool addresses
   - Create single vault per test file

2. **Range Position Management**
   - Set appropriate UPPER_PRICE_LIMIT and LOWER_PRICE_LIMIT for each DEX
   - Convert price limits to ticks via LibDEXMaths
   - Verify `setWeights` and `zeroOutWeights` functionality (ALMProtectedFacet)

3. **Rebalancing Tests**
   - Equal Rebalance: Same range, no swaps needed
   - Full Rebalance: Different range requiring swaps (using CLI `btr-swap`) 
   - Test individual range management functions (`burnRanges`, `mintRanges`, `remintRanges`)
   - Track residual token balances after swaps
   - Validate preview functions (`prepareRebalance`, `previewBurnRanges`)

4. **User Flow Testing**
   - Test all deposit variants:
     - Regular deposit (token amounts)
     - Safe deposit (with minimum shares)
     - Exact token0/token1 deposits
     - Mint (share-based)
   - Test all withdrawal variants:
     - Regular withdraw (token amounts)
     - Safe withdraw (with maximum burnt shares)
     - Exact token0/token1 withdrawals
     - Redeem (share-based)
   - Test preview functions match actual operation results
   - Validate all "safe" variants revert when constraints are not met
   - Verify fees are correctly collected by treasury

5. **Vault Management Testing**
   - Test pause/unpause functionality
   - Validate mint restrictions (restrictMint)
   - Test totalSupply, maxSupply limits

## Review Plan

- Audit diamond deployment flows via `make build` or `build.sh` and `DiamondCutFacet` for correct facet inclusion and `onlyAdmin` protection. Check tests in `DiamondTest.t.sol`.
- Verify `setDexAdapter` and `setPoolInfo` enforce `onlyManager` and handle idempotency and error cases (primarily tested via setup in `BaseALMTest.t.sol`).
- Confirm `createVault` initialization logic and `onlyAdmin` access control (tested via `BaseALMTest.t.sol`).
- Ensure all vault upkeep functions (`rebalance`, `mintRanges`, `remintRanges` and `burnRanges`) are gated by `onlyKeeper`.
- Verify all vault management functions (`pauseAlmVault`, `unpauseAlmVault`, `restrictMint`, `setWeights`, `zeroOutWeights`) are protected by `onlyManager`.
- Check that only the treasury's fee collector can call `collectAlmFees` (tested in `TreasuryTest.t.sol`).
- Validate user flows (all deposit and withdrawal variants) apply `whenVaultNotPaused`, `nonReentrant`, and correct fee logic (tested in `BaseALMTest.t.sol` and children).
- Verify all preview functions return accurate estimates that match actual operation results.
- Review safety mechanisms in "safe" variants of user functions to ensure they properly revert when constraints aren't met.
- Review ERC1155 vault operations (`mint`, `burn` in `ERC1155VaultsFacet`) enforce `onlyUnrestrictedMinter` and maintain NFT accounting integrity (tested implicitly in ALM flows).
- Audit sensitive modifiers across facets (`onlyAdmin`, `onlyManager`, `onlyKeeper`, `onlyTreasury`, `onlyUnrestrictedMinter`, `whenVaultNotPaused`, `nonReentrant`) and ensure coverage in relevant unit tests (`AccessControlTest.t.sol`, `ManagementTest.t.sol`, `TreasuryTest.t.sol`, `RescueTest.t.sol`) and integration tests (`BaseALMTest.t.sol` ...).
- Identify test coverage gaps for preview APIs, full-rebalance swap paths, edge-case fee scenarios, and inverted-pair support.

## Additional Considerations
- Token sorting consistency across pools is critical; test reverse-order tokens to verify adapters handle this correctly.
- Vault-level accounting must be solid - especially for leftover tokens after rebalances. Current implementation does not keep track of excess tokens per vault, only active positions (dust/excess liquidity after rebalance swaps+deposits are all accrued to the Diamond address, which will be problematic)
- Protocol fees must be accurately tracked and accrued per vault and collectible by the treasury. Pending fees should be reset per-vault when collected.
- Test full information flow through ALMInfoFacet to verify all view functions accurately represent vault state.
