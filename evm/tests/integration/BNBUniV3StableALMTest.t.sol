// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DEX, Range, PoolInfo} from "@/BTRTypes.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniV3Router} from "@interfaces/dexs/IUniV3Router.sol";
import {BaseALMTest} from "./BaseALMTest.t.sol";
import {BnbChainMeta} from "@utils/meta/BNBChain.sol";
import {UniV3Adapter} from "@dexs/UniV3Adapter.sol";
import {console} from "forge-std/Test.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BNB Uniswap V3 Stable ALM Test - Integration tests for ALM on Uniswap V3 stable pools on BNB Chain
 * @copyright 2025
 * @notice Verifies ALM functionality specifically for stablecoin pairs on Uniswap V3 on BNB Chain
 * @dev Inherits from BaseALMTest and BNBChainMeta to cover full vault lifecycle
 * @author BTR Team
 */

contract BNBUniV3StableALMTest is BaseALMTest, BnbChainMeta {
    address public uniV3Adapter;
    address internal constant UNISWAP_V3_ROUTER = 0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2;

    function tokens() internal view override returns (address, address) {
        return __testStables();
    }

    function dexs() internal view override returns (DEX[] memory) {
        DEX[] memory d = new DEX[](1);
        d[0] = DEX.UNISWAP;
        return d;
    }

    function adapterst() internal view override returns (address[] memory) {
        address[] memory a = new address[](1);
        a[0] = uniV3Adapter;
        return a;
    }

    function pools() internal view override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](1);
        v3[0] = UNIV3_USDT_USDC_POOL;
        // v4 = [UNIV4_USDT_USDC_POOL];
    }

    function weights() internal view override returns (uint16[] memory) {
        uint16[] memory w = new uint16[](1);
        w[0] = 100_00;
        return w; // single range
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
        super.setUp();
    }

    function testVaultLifecycle() public {
        testVaultLifecycle();
    }

    function testRebalanceWithSwaps() public override {
        super.testRebalanceWithSwaps();
    }
}
