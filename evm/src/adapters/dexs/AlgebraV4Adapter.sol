// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAlgebraV4Pool} from "@interfaces/dexs/IAlgebraV4Pool.sol";
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
 * @title Algebra V4 Adapter - Algebra V4 integration
 * @copyright 2025
 * @notice Implements Algebra V4 specific DEX operations
 * @dev Inherits from V3Adapter
 * @author BTR Team
 */

contract AlgebraV4Adapter is V3Adapter {
    using SafeERC20 for IERC20;

    constructor(address _diamond) V3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IAlgebraV4Pool(_pool).safelyGetStateOfAMM();
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
        // Handle return types from positions - liquidity is uint256, need to cast to uint128
        (uint256 liquidity256, uint256 innerFeeGrowth0X128, uint256 innerFeeGrowth1X128, uint128 fees0, uint128 fees1) =
            IAlgebraV4Pool(_pool).positions(_positionKey);
        // Safe cast from uint256 to uint128, assumption: liquidity fits in uint128
        liquidity = uint128(liquidity256);
        feeGrowthInside0LastX128 = innerFeeGrowth0X128;
        feeGrowthInside1LastX128 = innerFeeGrowth1X128;
        tokensOwed0 = fees0;
        tokensOwed1 = fees1;
    }

    function _mintPosition(
        address _pool,
        address _recipientForPool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        bytes calldata _callbackDataForPool
    ) internal virtual override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1,) = IAlgebraV4Pool(_pool).mint(
            address(this), // leftoverRecipient
            _recipientForPool, // recipient
            _tickLower,
            _tickUpper,
            _liquidity,
            _callbackDataForPool
        );
    }

    function _burnPosition(address _pool, int24 _tickLower, int24 _tickUpper, uint128 _liquidity)
        internal
        virtual
        override
        returns (uint256 amount0, uint256 amount1)
    {
        // Burn position to release tokens, V4 has additional data parameter
        (amount0, amount1) = IAlgebraV4Pool(_pool).burn(
            _tickLower,
            _tickUpper,
            _liquidity,
            abi.encode(_pool) // Additional data parameter in V4
        );
    }

    // V4 uses the same callback but may need to be implemented differently
    function algebraMintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external {
        (address poolAddressFromData, address payerAddress) = abi.decode(_data, (address, address));

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
