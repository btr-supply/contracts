I would like to ensure comprehensive testing for our infrastructure involving @ALMFacet.sol, @LibALM.sol, @DEXAdapterFacet.sol, @V3AdapterFacet.sol, @UniV3AdapterFacet.sol, @CakeV3AdapterFacet.sol, and @ThenaV3AdapterFacet.sol. The tests will be implemented in the following files: @CakeV3StableALMTest.t.sol, @ThenaV3StableALMTest.t.sol, and @UniV3StableALMTest.t.sol.

Each test will cover the following aspects:

1. **Diamond Deployment**: Ensure the diamond pattern is correctly deployed with all necessary facets and initializations. This is a prerequisite for the tests to function.

2. **Pool Registration**: Register the pool information for the DEX/pool being tested. This includes:
   - ThenaV3 USDT/USDC: 0x1b9a1120a17617d8ec4dc80b921a9a1c50caef7d (as defined in @IThenaV3Pool.sol)
   - CakeV3 USDT/USDC: 0x92b7807bF19b7DDdf89b706143896d05228f3121 (as defined in @ICakeV3Pool.sol)
   - UniV3 USDT/USDC: 0x2C3c320D49019D4f9A92352e947c7e5AcFE47D68 (as defined in @IUniV3Pool.sol)

3. **Vault Creation**: Create a single vault per test. Testing with multiple vaults will be addressed in future iterations.

4. **Vault Initialization**: Open the first liquidity position using the default/test range. Define weights and prices as constants for the range boundaries (lower and upper) in token0/token1 in wad. A utility function in @LibDEXMaths.sol will convert these prices to ticks (lowerTick and upperTick as defined in @BTRTypes.sol).

5. **User Deposit**: Simulate a user deposit into the vault, which should increase the liquidity position in the correct proportions and amounts.

6. **Position Rebalance**: Rebalance the position by reusing the same range lower and upper limits to avoid altering token balance requirements and prevent swaps during rebalance. Alternatively, choose other limits with equivalent price differences to maintain balance.

7. **User Withdrawal**: Simulate a user withdrawal from the vault, triggering the burning of liquidity positions on the underlying DEXs pools.

The tests will be conducted on the BNB Chain, forked using the RPC URL specified in the .env variable HTTPS_RPC_56.

We anticipate that many test files will require updates, and some tests may break. Our code is not yet production-ready, so we must critically evaluate all call flows from @ALMFacet.sol through @DEXAdapterFacet.sol, @LibDEXMaths.sol, and the specific adapter facets (@ThenaV3AdapterFacet.sol, @UniV3AdapterFacet.sol, @CakeV3AdapterFacet.sol).

Additional considerations:
- Ensure tokens are sorted consistently across all pools, or add support for inverted pairs when necessary.
- Inherit from @BaseDiamondTest.t.sol for diamond setup.

We will proceed to more complex test cases after these foundational tests are established.
