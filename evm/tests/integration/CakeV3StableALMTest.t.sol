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
 * @title CakeV3 Stable ALM Test - Integration tests for ALM on PancakeSwap V3 stable pools
 * @copyright 2025
 * @notice Verifies ALM functionality specifically for stablecoin pairs on PancakeSwap V3
 * @dev Inherits from ALMBaseTest
 * @author BTR Team
 */

import {BNBALMTest} from "./BNBALMTest.t.sol";
import "forge-std/console.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {ALMVault, Range, Rebalance, DEX} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {CakeV3AdapterFacet} from "@facets/adapters/dexs/CakeV3AdapterFacet.sol";

/**
 * @title CakeV3StableALMTest
 * @notice Integration test for ALM on PancakeSwap V3 stable pools
 * @dev Inherits from BNBALMTest to cover full vault lifecycle
 */
contract CakeV3StableALMTest is BNBALMTest {
    address public cakeV3Adapter;

    function setUp() public override {
        // Deploy CakeV3 adapter
        cakeV3Adapter = address(new CakeV3AdapterFacet());

        // Base setup: diamond, fork, token balances, pool registration
        super.setUp();

        // Register CakeV3 adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.PANCAKESWAP, cakeV3Adapter);
        vm.stopPrank();
    }

    /// @notice Lifecycle test: create vault, init range, deposit, rebalance, withdraw
    function testCakeV3Lifecycle() public {
        runLifecycleTest(true);
    }

    /// @notice Fee collection test
    function testCakeV3FeeCollection() public {
        runFeeCollectionTest(true);
    }

    function getTestStablePool() internal view override returns (address) {
        return CAKEV3_USDT_USDC_POOL;
    }

    function getTestAdapter() internal view override returns (address) {
        return cakeV3Adapter;
    }

    function getTestDEX() internal view override returns (DEX) {
        return DEX.PANCAKESWAP;
    }
}
