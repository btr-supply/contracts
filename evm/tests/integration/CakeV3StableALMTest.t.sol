// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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
 * @notice Integration test for PancakeSwap V3 stable pools
 * @dev Tests range creation, rebalancing with swaps
 */
contract CakeV3StableALMTest is BNBALMTest {
    address public cakeV3Adapter;

    function setUp() public override {
        // Deploy CakeV3 adapter before calling parent setup
        cakeV3Adapter = address(new CakeV3AdapterFacet());

        // Call parent setup
        super.setUp();

        // Register CakeV3 adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.PANCAKESWAP, cakeV3Adapter);
        vm.stopPrank();
    }

    // Override base test abstract functions

    function getTestStablePool() internal view override returns (address) {
        return CAKEV3_USDT_USDC_POOL;
    }

    function getTestAdapter() internal view override returns (address) {
        return cakeV3Adapter;
    }

    function getTestDEX() internal view override returns (DEX) {
        return DEX.PANCAKESWAP;
    }

    // PancakeSwap-specific tests

    function testCakeV3Lifecycle() public {
        runLifecycleTest(true);
    }

    function testCakeV3FeeCollection() public {
        runFeeCollectionTest(true);
    }
}
