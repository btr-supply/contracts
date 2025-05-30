// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DEX} from "@/BTRTypes.sol";
import {BaseALMTest} from "./BaseALMTest.t.sol";
import {BnbChainMeta} from "@utils/meta/BNBChain.sol";
import {CakeV3Adapter} from "@dexs/CakeV3Adapter.sol";
import {ThenaV3Adapter} from "@dexs/ThenaV3Adapter.sol";
import {UniV3Adapter} from "@dexs/UniV3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BNB Multi V3 DEX Stable Test - Integration tests for ALM on multiple V3 stable pools on BNB
 * @copyright 2025
 * @notice Verifies the SwapFacet's ability to route trades across different DEX adapters on BNB Chain
 * @dev Tests aggregation or multi-hop swap logic
 * @author BTR Team
 */

contract BNBMultiV3StableTest is BaseALMTest, BnbChainMeta {
    address public uniV3Adapter;
    address public cakeAdapter;
    address public thenaAdapter;

    function tokens() internal view override returns (address, address) {
        return __testStables();
    }

    function dexs() internal view override returns (DEX[] memory) {
        DEX[] memory d = new DEX[](3);
        d[0] = DEX.UNISWAP;
        d[1] = DEX.PANCAKESWAP;
        d[2] = DEX.THENA;
        return d;
    }

    function adapterst() internal view override returns (address[] memory) {
        address[] memory a = new address[](3);
        a[0] = uniV3Adapter;
        a[1] = cakeAdapter;
        a[2] = thenaAdapter;
        return a;
    }

    function pools() internal view override returns (address[] memory v3, bytes32[] memory v4) {
        return __testStablePools();
    }

    function weights() internal view override returns (uint16[] memory) {
        uint16[] memory w = new uint16[](3);
        w[0] = 20_00;
        w[1] = 30_00;
        w[2] = 50_00;
        return w;
    }

    function narrowRange() internal view override returns (uint256 min, uint256 max) {
        min = 0.995e18;
        max = 1.005e18;
    }

    function wideRange() internal view override returns (uint256 min, uint256 max) {
        min = 0.97e18;
        max = 1.03e18;
    }

    function depositSingle0() internal view override returns (uint256) {
        return 1000; // 1k USDC
    }

    function setUp() public override {
        uniV3Adapter = address(new UniV3Adapter());
        cakeAdapter = address(new CakeV3Adapter());
        thenaAdapter = address(new ThenaV3Adapter());
        super.setUp();
    }

    function testVaultLifecycle() public {
        testVaultLifecycle();
    }
}
