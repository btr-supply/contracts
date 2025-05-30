// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRamsesV3Pool} from "@interfaces/dexs/IRamsesV3Pool.sol";
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
 * @title Ramses V3 Adapter - Ramses V3 integration
 * @copyright 2025
 * @notice Implements Ramses V3 specific DEX operations
 * @dev Inherits from UniV3Adapter
 * @author BTR Team
 */

contract RamsesV3Adapter is UniV3Adapter {
    using SafeERC20 for IERC20;

    constructor(address _diamond) UniV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IRamsesV3Pool(_pool).slot0();
    }

    function _observe(address _pool, uint32[] memory _secondsAgos)
        internal
        view
        virtual
        override
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128)
    {
        (tickCumulatives, secondsPerLiquidityCumulativeX128,) = IRamsesV3Pool(_pool).observe(_secondsAgos);
    }

    function _getPosition(address _pool, bytes32 _positionKey)
        internal
        view
        override
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1,) =
            IRamsesV3Pool(_pool).positions(_positionKey);
    }

    function ramsesV2MintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external {
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
