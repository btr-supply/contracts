// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAlgebraV3Pool} from "@interfaces/dexs/IAlgebraV3Pool.sol";
import {IQuickV3Pool} from "@interfaces/dexs/IQuickV3Pool.sol";
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
 * @title Algebra V3 Adapter - Algebra V3 integration
 * @copyright 2025
 * @notice Implements Algebra V3 specific DEX operations
 * @dev Inherits from V3Adapter
 * @author BTR Team
 */

contract AlgebraV3Adapter is V3Adapter {
    using SafeERC20 for IERC20;

    constructor(address _diamond) V3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IQuickV3Pool(_pool).globalState();
    }

    function _observe(address _pool, uint32[] memory _secondsAgos)
        internal
        view
        virtual
        override
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128)
    {
        (tickCumulatives, secondsPerLiquidityCumulativeX128,,) = IAlgebraV3Pool(_pool).getTimepoints(_secondsAgos);
    }

    function _getPosition(address _pool, bytes32 _positionKey)
        internal
        view
        virtual
        override
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1) =
            IAlgebraV3Pool(_pool).positions(_positionKey);
    }

    function _mintPosition(
        address _pool,
        address _recipientForPool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        bytes calldata _callbackDataForPool
    ) internal virtual override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1,) = IAlgebraV3Pool(_pool).mint(
            _recipientForPool, address(this), _tickLower, _tickUpper, _liquidity, _callbackDataForPool
        );
    }

    function _burnPosition(address _pool, int24 _tickLower, int24 _tickUpper, uint128 _liquidity)
        internal
        virtual
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = IAlgebraV3Pool(_pool).burn(_tickLower, _tickUpper, _liquidity);
    }

    function algebraMintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external {
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
