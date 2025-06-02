// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Vm} from "forge-std/Vm.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Swap Utils Test - Utilities for swap testing
 * @copyright 2025
 * @notice Provides helper functions for generating swap data and testing swap operations
 * @dev Helper utilities for swap integration tests
 * @author BTR Team
 */

library BTRSwapUtils {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);
    /// @param inputToken the address of the token to swap from
    /// @param outputToken the address of the token to swap to
    /// @param amountIn the amount of input token to swap (in wei)
    /// @return to the swap router contract address
    /// @return approveTo the address that must be approved
    /// @return value the native value to send with the call
    /// @return data the calldata for the swap call

    function generateSwapData(address inputToken, address outputToken, uint256 amountIn)
        internal
        returns (address to, address approveTo, uint256 value, bytes memory data)
    {
        // Fetch current chain ID
        uint256 chainId = block.chainid;
        // Pull token metadata
        string memory inputSymbol = IERC20Metadata(inputToken).symbol();
        string memory outputSymbol = IERC20Metadata(outputToken).symbol();
        uint8 inputDecimals = IERC20Metadata(inputToken).decimals();
        uint8 outputDecimals = IERC20Metadata(outputToken).decimals();

        // Build parameter strings: "{chainId}:{tokenAddress}:{symbol}:{decimals}"
        string memory inputParam = string(
            abi.encodePacked(
                vm.toString(chainId), ":", vm.toString(inputToken), ":", inputSymbol, ":", vm.toString(inputDecimals)
            )
        );
        string memory outputParam = string(
            abi.encodePacked(
                vm.toString(chainId), ":", vm.toString(outputToken), ":", outputSymbol, ":", vm.toString(outputDecimals)
            )
        );
        // Convert amountIn to string
        string memory amount = vm.toString(amountIn);

        // Prepare FFI command
        string[] memory cmd = new string[](6);
        cmd[0] = "bash";
        cmd[1] = "../scripts/get_swap_data.sh";
        cmd[2] = inputParam;
        cmd[3] = outputParam;
        cmd[4] = amount;
        cmd[5] = vm.envString("DEPLOYER");

        // Execute and parse CSV
        string memory csv = string(vm.ffi(cmd));
        string[] memory parts = vm.split(csv, ",");
        require(parts.length == 5, "Invalid swap data CSV");

        // CSV format: nonce,to,approveTo,value,data
        to = vm.parseAddress(parts[1]);
        approveTo = vm.parseAddress(parts[2]);
        value = vm.parseUint(parts[3]);
        data = vm.parseBytes(parts[4]);
    }
}
