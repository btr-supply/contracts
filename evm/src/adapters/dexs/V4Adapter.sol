// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {Range} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DEXAdapter} from "@dexs/DEXAdapter.sol";

// Suppress warnings for virtual functions with unused parameters (intended for override)
// solhint-disable func-param-name-mixedcase, no-unused-vars

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title V4 Adapter Base - Abstract base for V4-style DEX adapters
 * @copyright 2025
 * @notice Provides shared V4 functionality for adapter implementations
 * @dev Base contract for V4-based DEX integrations using singleton pattern and unlock mechanism
 * @author BTR Team
 */

abstract contract V4Adapter is DEXAdapter {
    using SafeERC20 for IERC20;
    using C for uint256;
    using C for bytes32;
    using M for uint256;
    using DM for int24;
    using DM for uint160;

    // === V4 CORE STRUCTS ===
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    constructor(address _diamond) DEXAdapter(_diamond) {}

    // === ABSTRACT FUNCTIONS FOR V4 CONTRACTS ===
    function poolManager() external view virtual returns (address);
    function positionManager() external view virtual returns (address);
    function stateView() external view virtual returns (address);

    // === POOL KEY HELPERS ===
    function _poolKeyFromId(bytes32 _pid) internal view virtual returns (PoolKey memory poolKey);
    function _poolIdFromKey(PoolKey memory _poolKey) internal pure virtual returns (bytes32) {
        return keccak256(
            abi.encode(_poolKey.currency0, _poolKey.currency1, _poolKey.fee, _poolKey.tickSpacing, _poolKey.hooks)
        );
    }

    // === ABSTRACT V4 OPERATIONS ===
    /**
     * @notice Execute V4 unlock pattern operation
     * @dev Must be implemented by concrete adapters to handle unlock callback
     */
    function unlockCallback(bytes calldata data) external virtual returns (bytes memory);

    /**
     * @notice Get TWAP price (V4 requires custom oracle implementation via hooks)
     * @dev V4 has no built-in oracle, must be implemented via hooks or external oracles
     */
    function _getTWAP(bytes32 _pid, uint32 /* _lookback */) internal view virtual returns (uint160 twapPriceX96) {
        // V4 has no built-in oracle - must be implemented via hooks
        // Default implementation returns current price as fallback
        (uint160 currentPrice,) = _poolState(_pid);
        return currentPrice;
    }

    /**
     * @notice V4 fee collection via PositionManager
     * @dev V4 uses DECREASE_LIQUIDITY with zero change + TAKE_PAIR pattern
     */
    function _collectFeesV4(Range calldata _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        returns (uint256 collectedFee0, uint256 collectedFee1);

    // === V4 SAFE POOL STATE WITH CUSTOM ORACLE ===
    function _safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        override
        returns (
            uint160 priceX96,
            int24 tick,
            uint160 twapPriceX96,
            bool isStale,
            uint256 deviation
        )
    {
        (priceX96, tick) = _poolState(_pid);
        twapPriceX96 = _getTWAP(_pid, _lookback);
        (isStale, deviation) = DM.deviationState(priceX96, twapPriceX96, _maxDeviationBp);
    }

    // === V4 LIQUIDITY CALCULATIONS ===
    function _liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (, int24 currentTick) = _poolState(_pid);
        return DM.liquidityToAmountsTickV3(currentTick, _lowerTick, _upperTick, _liquidityValue);
    }

    function _amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) internal view virtual override returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual) {
        (uint160 priceX96,) = _poolState(_pid);
        uint160 sqrtRatioAX96 = _lowerTick.tickToPriceX96V3();
        uint160 sqrtRatioBX96 = _upperTick.tickToPriceX96V3();

        liquidity = DM.amountsToLiquidityPriceX96V3(priceX96, sqrtRatioAX96, sqrtRatioBX96, _amount0Desired, _amount1Desired);

        // Recalculate actual amounts for the derived liquidity
        if (priceX96 <= sqrtRatioAX96) {
            // current price is below the range
            amount0Actual = DM.liquidityToAmount0PriceX96V3(sqrtRatioAX96, sqrtRatioBX96, liquidity);
            amount1Actual = 0;
        } else if (priceX96 < sqrtRatioBX96) {
            // current price is inside the range
            amount0Actual = DM.liquidityToAmount0PriceX96V3(priceX96, sqrtRatioBX96, liquidity);
            amount1Actual = DM.liquidityToAmount1PriceX96V3(sqrtRatioAX96, priceX96, liquidity);
        } else {
            // current price is above the range
            amount0Actual = 0;
            amount1Actual = DM.liquidityToAmount1PriceX96V3(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }

    // === V4 FEE COLLECTION IMPLEMENTATION ===
    function _collectRangeFees(Range calldata _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        override
        returns (uint256 collectedFee0, uint256 collectedFee1)
    {
        return _collectFeesV4(_range, _recipient, _callbackData);
    }
}
