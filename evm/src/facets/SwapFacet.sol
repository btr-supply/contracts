// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {AccountStatus as AS} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibManagement as M} from "@libraries/LibManagement.sol";
import {LibRescue as R} from "@libraries/LibRescue.sol";
import {LibSwap as SW} from "@libraries/LibSwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Swap Facet - Handles token swaps via DEX adapters
 * @copyright 2025
 * @notice Provides unified interface for executing swaps across different DEXs
 * @dev Routes swaps through registered DEX adapters via `LibSwap`
- Security Sensitive: Handles external calls to DEXs. Relies on adapter security and input validation
- Modifiers: `swap` implicitly checks restrictions set in `ManagementFacet`. `initializeSwap` uses `onlyAdmin`

 * @author BTR Team
 */

contract SwapFacet is PermissionedFacet {
    using SafeERC20 for IERC20;
    using R for address;
    using AC for bytes32;

    function initializeSwap() external onlyAdmin {
        SW.initialize();
    }

    // --- SWAP FUNCTIONS ---

    function swap(address _input, address _output, address _router, bytes calldata _callData) external {
        SW.swap(S.rst(), _input, _output, _router, _callData);
    }

    function safeSwap(
        address _input,
        address _output,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _targetRouter,
        bytes calldata _callData
    ) external returns (uint256 received, uint256 spent) {
        return SW.safeSwap(S.rst(), _input, _output, _amountIn, _minAmountOut, _targetRouter, msg.sender, _callData); // Standard swap with safety checks
    }

    function swapBalance(
        address _input,
        address _output,
        uint256 _minAmountOut,
        address _targetRouter,
        bytes calldata _callData
    ) external returns (uint256 received, uint256 spent) {
        return SW.swapBalance(S.rst(), _input, _output, _minAmountOut, _targetRouter, msg.sender, _callData); // Uses entire token balance
    }

    function decodeAndSwap(address _input, address _output, uint256 _amount, bytes memory _params)
        external
        returns (uint256 received, uint256 spent)
    {
        return SW.decodeAndSwap(S.rst(), _input, _output, _amount, msg.sender, _params); // Decodes and executes swap
    }

    function decodeAndSwapBalance(address _input, address _output, bytes memory _params)
        external
        returns (uint256 received, uint256 spent)
    {
        return SW.decodeAndSwapBalance(S.rst(), _input, _output, msg.sender, _params); // Decodes and swaps entire balance
    }
}
