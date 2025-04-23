// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title UniV3 Stable ALM Test - Integration tests for ALM on Uniswap V3 stable pools
 * @copyright 2025
 * @notice Verifies ALM functionality specifically for stablecoin pairs on Uniswap V3
 * @dev Inherits from ALMBaseTest
 * @author BTR Team
 */

import {Test, console} from "forge-std/Test.sol";
import {BNBALMTest} from "./BNBALMTest.t.sol";
import {DEX, Range, Rebalance, VaultInitParams, PoolInfo} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {UniV3AdapterFacet} from "@facets/adapters/dexs/UniV3AdapterFacet.sol";
import {DEXAdapterFacet} from "@facets/abstract/DEXAdapterFacet.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import {BNBChainMeta} from "./ChainMeta.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {LibDEXMaths} from "@libraries/LibDEXMaths.sol";
import {LibMaths} from "@libraries/LibMaths.sol";

/**
 * @title UniV3StableALMTest
 * @notice Integration test for ALM on Uniswap V3 stable pools
 * @dev Inherits from BNBALMTest to cover full vault lifecycle
 */
contract UniV3StableALMTest is BNBALMTest {
    address public uniV3Adapter;

    function setUp() public override {
        // Deploy UniV3 adapter
        uniV3Adapter = address(new UniV3AdapterFacet());

        // Base setup: diamond, fork, token balances, pool registration
        super.setUp();

        // Register UniV3 adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.UNISWAP, uniV3Adapter);
        vm.stopPrank();
    }

    /// @notice Lifecycle test: create vault, init range, deposit, rebalance, withdraw
    function testUniV3Lifecycle() public {
        runLifecycleTest(true);
    }

    /// @notice Fee collection test
    function testUniV3FeeCollection() public {
        runFeeCollectionTest(true);
    }

    function getTestStablePool() internal view override returns (address) {
        return UNIV3_USDT_USDC_POOL;
    }

    function getTestAdapter() internal view override returns (address) {
        return uniV3Adapter;
    }

    function getTestDEX() internal view override returns (DEX) {
        return DEX.UNISWAP;
    }
}
