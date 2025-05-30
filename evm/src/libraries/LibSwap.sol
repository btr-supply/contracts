// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccountStatus as AS, ErrorType, Restrictions} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibManagement as M} from "@libraries/LibManagement.sol";
import {LibMaths} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Swap Library - Token swapping logic
 * @copyright 2025
 * @notice Contains internal functions for executing swaps via DEX adapters
 * @dev Executes and aggregates swap calls across registered adapter facets
- Exposed via `SwapFacet`; supports multi-hop, cross-DEX routing

 * @author BTR Team
 */

library LibSwap {
    using SafeERC20 for IERC20;
    using LibMaths for uint256;

    struct SwapData {
        IERC20 input;
        IERC20 output;
        uint256 inputBefore;
        uint256 outputBefore;
        uint256 leftover;
    }

    // --- INITIALIZATION ---

    function initialize() internal {}

    // --- SWAP LOGIC ---

    function swap(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        address _router,
        bytes memory _callData
    ) internal {
        if (
            M.isSwapRouterRestricted(_restrictions, _router) || M.isSwapInputRestricted(_restrictions, _input)
                || M.isSwapOutputRestricted(_restrictions, _output)
        ) {
            revert Errors.Unauthorized(ErrorType.ROUTER);
        }

        IERC20(_input).forceApprove(_router, type(uint256).max);

        (bool success,) = _router.call(_callData);
        if (!success) revert Errors.RouterError();

        if (M.isAutoRevoke(_restrictions)) {
            IERC20(_input).forceApprove(_router, 0);
        }
    }

    function _validateSwapPermissions(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        address _router,
        address _caller
    ) private view {
        if (
            M.isSwapCallerRestricted(_restrictions, _caller) || M.isSwapRouterRestricted(_restrictions, _router)
                || M.isSwapInputRestricted(_restrictions, _input) || M.isSwapOutputRestricted(_restrictions, _output)
        ) {
            revert Errors.Unauthorized(ErrorType.ADDRESS);
        }
    }

    function _executeSwap(
        Restrictions storage _restrictions,
        SwapData memory _data,
        uint256 _amountIn,
        address _router,
        address _caller,
        bytes memory _callData
    ) private returns (uint256 received, uint256 spent) {
        _data.input.safeTransferFrom(_caller, address(this), _amountIn);
        _data.inputBefore = _data.input.balanceOf(address(this));
        _data.outputBefore = _data.output.balanceOf(_caller);

        if (_data.input.allowance(address(this), _router) < _amountIn) {
            _data.input.forceApprove(_router, M.isApproveMax(_restrictions) ? type(uint256).max : _amountIn);
        }

        (bool success,) = _router.call(_callData);
        if (!success) revert Errors.RouterError();

        unchecked {
            received = _data.output.balanceOf(_caller).subMax0(_data.outputBefore);
            spent = _data.inputBefore.subMax0(_data.input.balanceOf(address(this)));
        }
    }

    function safeSwap(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _router,
        address _caller,
        bytes memory _callData
    ) internal returns (uint256 received, uint256 spent) {
        _validateSwapPermissions(_restrictions, _input, _output, _router, _caller);

        SwapData memory data;
        data.input = IERC20(_input);
        data.output = IERC20(_output);

        (received, spent) = _executeSwap(_restrictions, data, _amountIn, _router, _caller, _callData);

        if (received == 0 || spent == 0) revert Errors.UnexpectedOutput();
        if (received < _minAmountOut) revert Errors.SlippageTooHigh();

        data.leftover = _amountIn.subMax0(spent);
        if (data.leftover > 0) data.input.safeTransfer(_caller, data.leftover);

        if (M.isAutoRevoke(_restrictions)) {
            data.input.forceApprove(_router, 0);
        }
        emit Events.Swapped(_caller, _input, _output, spent, received);
    }

    function swapBalance(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        uint256 _minAmountOut,
        address _router,
        address _caller,
        bytes memory _callData
    ) internal returns (uint256 received, uint256 spent) {
        uint256 balance = IERC20(_input).balanceOf(_caller);
        if (balance == 0) revert Errors.ZeroValue();
        return safeSwap(_restrictions, _input, _output, balance, _minAmountOut, _router, _caller, _callData);
    }

    function decodeAndSwap(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        uint256 _amount,
        address _caller,
        bytes memory _params
    ) internal returns (uint256 received, uint256 spent) {
        (address router, uint256 minAmountOut, bytes memory callData) = decodeSwapParams(_params);
        return safeSwap(_restrictions, _input, _output, _amount, minAmountOut, router, _caller, callData);
    }

    function decodeAndSwapBalance(
        Restrictions storage _restrictions,
        address _input,
        address _output,
        address _caller,
        bytes memory _params
    ) internal returns (uint256 received, uint256 spent) {
        uint256 balance = IERC20(_input).balanceOf(_caller);
        if (balance == 0) revert Errors.ZeroValue();
        (address router, uint256 minAmountOut, bytes memory callData) = decodeSwapParams(_params);
        return safeSwap(_restrictions, _input, _output, balance, minAmountOut, router, _caller, callData);
    }

    function decodeSwapParams(bytes memory _params)
        internal
        pure
        returns (address router, uint256 minAmount, bytes memory callData)
    {
        return abi.decode(_params, (address, uint256, bytes));
    }
}
