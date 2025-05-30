// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BTRSwapUtils} from "./BTRSwapUtils.t.sol";
import {BnbChainMeta} from "@utils/meta/BNBChain.sol";
import {Test, console} from "forge-std/Test.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Swap Test - Tests for swap functionality
 * @copyright 2025
 * @notice Verifies swap operations across different DEX adapters
 * @dev Tests the SwapFacet and related swap logic
 * @author BTR Team
 */

contract BTRSwapTest is Test, BnbChainMeta {
    function setUp() public {
        // Fork BNB Chain at head
        vm.createSelectFork(__id());
    }

    function testSwapQuoteCSV() public {
        // Setup deployer and token parameters
        address deployer = vm.envAddress("DEPLOYER");
        uint256 amountIn = 1e17; // 0.1 WBNB
        address inputTokenAddr = WBNB;
        address outputTokenAddr = usdc();

        // Fund deployer
        deal(inputTokenAddr, deployer, amountIn * 2);

        vm.startPrank(deployer);

        // Generate swap calldata and parsing
        (address to, address approveTo, uint256 value, bytes memory data) =
            BTRSwapUtils.generateSwapData(inputTokenAddr, outputTokenAddr, amountIn);

        // Validate swap parameters
        assertTrue(to != address(0) && approveTo != address(0), "Invalid swap addresses");
        assertTrue(data.length > 0, "Empty swap calldata");

        // Record balances before swap
        uint256 balanceInBefore = IERC20(inputTokenAddr).balanceOf(deployer);
        uint256 balanceOutBefore = IERC20(outputTokenAddr).balanceOf(deployer);

        // Approve and execute swap
        IERC20(inputTokenAddr).approve(approveTo, amountIn);
        (bool success, bytes memory ret) = to.call{value: value}(data);
        if (!success) {
            console.logBytes(ret);
            revert("Swap call failed");
        }

        // Record balances after swap
        uint256 balanceInAfter = IERC20(inputTokenAddr).balanceOf(deployer);
        uint256 balanceOutAfter = IERC20(outputTokenAddr).balanceOf(deployer);

        // Assertions: input spent and output received
        assertTrue(balanceInAfter < balanceInBefore, "Input not spent");
        assertTrue(balanceOutAfter > balanceOutBefore, "Output not received");

        vm.stopPrank();
    }
}
