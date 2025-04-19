// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BNBALMTest} from "./BNBALMTest.t.sol";
import "forge-std/console.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {ALMVault, Range, Rebalance, DEX} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {ThenaV3AdapterFacet} from "@facets/adapters/dexs/ThenaV3AdapterFacet.sol";

/**
 * @title ThenaV3StableALMTest
 * @notice Integration test for Thena V3 stable pools
 * @dev Tests range creation, rebalancing with swaps
 */
contract ThenaV3StableALMTest is BNBALMTest {
    address public thenaV3Adapter;

    function setUp() public override {
        // Deploy ThenaV3 adapter before calling parent setup
        thenaV3Adapter = address(new ThenaV3AdapterFacet());

        // Call parent setup
        super.setUp();

        // Register ThenaV3 adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.THENA, thenaV3Adapter);
        vm.stopPrank();
    }

    // Override base test abstract functions

    function getTestStablePool() internal view override returns (address) {
        return THENAV3_USDT_USDC_POOL;
    }

    function getTestAdapter() internal view override returns (address) {
        return thenaV3Adapter;
    }

    function getTestDEX() internal view override returns (DEX) {
        return DEX.THENA;
    }

    // Thena-specific tests

    function testThenaV3Lifecycle() public {
        runLifecycleTest(true);
    }

    function testThenaV3FeeCollection() public {
        runFeeCollectionTest(true);
    }
}
