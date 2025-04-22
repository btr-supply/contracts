// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BNBChainMeta} from "./ChainMeta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title BTRSwapTest
/// @notice Integration test for BTRSwap using FFI to fetch swap data
contract BTRSwapTest is Test, BNBChainMeta {
    function setUp() public {
        // Fork BNB Chain at head
        vm.createSelectFork(RPC_URL);
    }

    function testSwapQuoteCSV() public {
        // Prepare CLI parameters for get-swap-data.sh
        string memory input = "56:0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c:WBNB:18";
        string memory output = "56:0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d:USDC:18";
        string memory amountIn = "1e17"; // 0.1 WBNB
        address deployer = vm.envAddress("DEPLOYER");

        // Construct FFI command array
        string[] memory cmd = new string[](6);
        cmd[0] = "bash";
        cmd[1] = "../scripts/get-swap-data.sh";
        cmd[2] = input;
        cmd[3] = output;
        cmd[4] = amountIn;
        cmd[5] = vm.envString("DEPLOYER"); // deployer == test payer

        // Call the external script via FFI
        string memory csv = string(vm.ffi(cmd));

        // Log the CSV output and ensure it's non-empty
        console.log("Swap quote CSV: %s", csv);
        assert(bytes(csv).length > 0);

        // Parse token addresses and amount
        address inputTokenAddr = vm.parseAddress(vm.split(input, ":")[1]);
        address outputTokenAddr = vm.parseAddress(vm.split(output, ":")[1]);
        uint256 amountInParsed = vm.parseUint(amountIn);

        // Parse the CSV data: nonce,to,approveTo,value,data
        string[] memory parts = vm.split(csv, ",");
        assert(parts.length == 5);

        // Use vm cheatcodes for parsing
        // uint256 nonce = bytes(parts[0]).length == 0 ? 0 : vm.parseUint(parts[0]); // Handle empty string case
        address to = vm.parseAddress(parts[1]);
        address approveTo = vm.parseAddress(parts[2]);
        uint256 value = vm.parseUint(parts[3]);
        bytes memory data = vm.parseBytes(parts[4]); // Assumes parts[4] starts with 0x

        // console.logUint(nonce);
        console.logAddress(to);
        console.logAddress(approveTo);
        console.logUint(value);
        console.logBytes(data);

        assert(to != address(0));
        assert(approveTo != address(0));
        assert(data.length > 0);

        // Give deployer some input tokens
        deal(inputTokenAddr, deployer, amountInParsed * 2); // Deal slightly more than needed

        // Import the deployer account
        vm.startPrank(deployer);

        // Record balances before and after swap in an array
        uint256[] memory balances = new uint256[](4);
        balances[0] = IERC20(inputTokenAddr).balanceOf(deployer);
        balances[1] = IERC20(outputTokenAddr).balanceOf(deployer);

        // Approve the router to spend input tokens
        IERC20(inputTokenAddr).approve(approveTo, amountInParsed);
        console.log("Approved %s to spend %s of %s", approveTo, amountInParsed, inputTokenAddr);

        // Execute swap (including native value if any)
        console.log("Calling swap contract %s with value %s", to, value);
        (bool success, bytes memory returnData) = address(to).call{value: value}(data);
        if (!success) {
            console.logBytes(returnData);
            revert("Swap call failed");
        }

        // Record balances after swap
        balances[2] = IERC20(inputTokenAddr).balanceOf(deployer);
        balances[3] = IERC20(outputTokenAddr).balanceOf(deployer);

        // Calculate amounts and rate
        uint256 amountSpent = balances[0] - balances[2];
        uint256 amountReceived = balances[3] - balances[1];
        uint256 exchangeRate = (amountReceived * 1e18) / amountSpent;

        console.log("Amount Spent (WBNB): %s", amountSpent);
        console.log("Amount Received (USDC): %s", amountReceived);
        console.log("Effective Rate (USDC per WBNB): %s.%s", exchangeRate / 1e18, exchangeRate % 1e18);

        // Assertions
        // Check if amount spent is within 0.1% tolerance of the input amount
        uint256 tolerance = amountInParsed / 1000; // 0.1%
        assertTrue(
            amountSpent >= amountInParsed - tolerance && amountSpent <= amountInParsed + tolerance,
            "Amount spent differs too much from input amount"
        );
        assertTrue(balances[3] - balances[1] > 0, "Did not receive any output tokens");

        vm.stopPrank();
    }
}
