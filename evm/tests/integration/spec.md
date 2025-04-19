I would like to write a test for @ALMFacet.sol + @LibALM.sol + @DEXAdapterFacet.sol + @V3AdapterFacet.sol + @UniV3AdapterFacet.sol + @CakeV3AdapterFacet.sol + @ThenaV3AdapterFacet.sol in a test file ./evm/tests/integration/BNBStableALMTest.sol

We will create a vault with 3 underlying ranges, on 3 different pools:
- ThenaV3 USDT/USDC: 0x1b9a1120a17617d8ec4dc80b921a9a1c50caef7d (pool as defined in @IThenaV3Pool.sol )
- CakeV3 USDT/USDC: 0x92b7807bF19b7DDdf89b706143896d05228f3121 (as defined in @ICakeV3Pool.sol )
- UniV3 USDT/USDC: 0x2C3c320D49019D4f9A92352e947c7e5AcFE47D68 (as defined in @IUniV3Pool.sol ).

This integration test will occur on the BNB Chain, which we will fork using the RPC url in the .env variable HTTPS_RPC_56.

We expect manny errors to occur as we proceed with implementing the integration test, that will require functional fixes in all of the tested files.

Our integration should cover:
- the test should define weights and prices as const for the range boundaries (lower and upper, defined in token0/token1 in wad. eg. 9.9e18 to 1.1e18 means we're looking to open a liquidity position between these two price rates, we therefore need a utility function to convert these prices to ticks (range lowerTick and upperTick as defined in @BTRTypes.sol ) this utility function can be in @LibDEXMaths.sol

- step1: adding the pools to the protocol registry
- step2: convert the constant prices (base 10 wad, rebased to the same decimal) to ticks that are pool compliant
- step3: simulate a user deposit -> triggers minting of the liquidity positions on the underlying DEXs pools (mint the liquidity),  creating the Range structs (using weights defined on the test)
- step4: simulat a user withdrawal -> triggers burning of the liquidity positions on the underlying DEXs pools (burns the liquidity)
- NB: we need to make sure the tokens are sorted in all pools the same way, or we need to add support for inverted pair (when uint(tokn0) > uint(token1))
- NB: inherit from @BaseDiamondTest.t.sol for diamond setup
we will then proceed to more complex test cases.
