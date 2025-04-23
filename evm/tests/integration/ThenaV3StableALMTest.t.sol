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
 * @title ThenaV3 Stable ALM Test - Integration tests for ALM on Thena V3 stable pools
 * @copyright 2025
 * @notice Verifies ALM functionality specifically for stablecoin pairs on Thena V3
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
import {ThenaV3AdapterFacet} from "@facets/adapters/dexs/ThenaV3AdapterFacet.sol";

/**
 * @title ThenaV3StableALMTest
 * @notice Integration test for ALM on Thena V3 stable pools
 * @dev Inherits from BNBALMTest to cover full vault lifecycle
 */
contract ThenaV3StableALMTest is BNBALMTest {
    address public thenaV3Adapter;

    function setUp() public override {
        // Deploy ThenaV3 adapter
        thenaV3Adapter = address(new ThenaV3AdapterFacet());

        // Base setup: diamond, fork, token balances, pool registration
        super.setUp();

        // Register ThenaV3 adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.THENA, thenaV3Adapter);
        vm.stopPrank();
    }

    /// @notice Lifecycle test: create vault, init range, deposit, rebalance, withdraw
    function testThenaV3Lifecycle() public {
        runLifecycleTest(true);
    }

    /// @notice Fee collection test
    function testThenaV3FeeCollection() public {
        runFeeCollectionTest(true);
    }

    function getTestStablePool() internal view override returns (address) {
        return THENAV3_USDT_USDC_POOL;
    }

    function getTestAdapter() internal view override returns (address) {
        return thenaV3Adapter;
    }

    function getTestDEX() internal view override returns (DEX) {
        return DEX.THENA;
    }
}
