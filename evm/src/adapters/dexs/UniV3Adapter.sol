// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {V3Adapter} from "@dexs/V3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Uniswap V3 Adapter - Uniswap V3 integration
 * @copyright 2025
 * @notice Implements Uniswap V3 specific DEX operations
 * @dev Inherits from V3Adapter
 * @author BTR Team
 */

contract UniV3Adapter is V3Adapter {
    using SafeERC20 for IERC20;

    constructor(address _diamond) V3Adapter(_diamond) {}

    function uniswapV3MintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data)
        external
        override
    {
        (address poolFromData, address payerAddress) = abi.decode(_data, (address, address));

        // msg.sender should be the pool that this callback is registered for.
        if (msg.sender == address(0)) revert Errors.ZeroAddress();

        (IERC20 token0, IERC20 token1) = _poolTokens(msg.sender);

        if (_amount0Owed > 0) {
            token0.safeTransferFrom(payerAddress, msg.sender, _amount0Owed);
        }
        if (_amount1Owed > 0) {
            token1.safeTransferFrom(payerAddress, msg.sender, _amount1Owed);
        }
    }
}
