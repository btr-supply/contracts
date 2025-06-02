// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

// Suppress warnings for virtual functions with unused parameters (intended for override)
// solhint-disable func-param-name-mixedcase, no-unused-vars

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibDEXUtils as DU} from "@libraries/LibDEXUtils.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDEXAdapter} from "@interfaces/IDEXAdapter.sol";
import {Permissioned} from "@/abstract/Permissioned.sol";
import {Range} from "@/BTRTypes.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title DEX Adapter Base - Base contract for DEX integrations
 * @copyright 2025
 * @notice Base contract for decentralized exchange integrations providing common functionality
 * @dev Used by adapter facets for shared DEX logic
 * @author BTR Team
 */

abstract contract DEXAdapter is IDEXAdapter, Permissioned {
    using SafeERC20 for IERC20;
    using C for uint256;
    using M for uint256;
    using DM for int24;
    using DM for uint160;

    // --- Constructor ---
    /*
    * @param _diamond The address of the BTRDiamond for permission checks
    */
    constructor(address _diamond) Permissioned(_diamond) {}

    // Pool Tokens
    function _poolTokens(bytes32 _pid) internal view virtual returns (IERC20 token0, IERC20 token1);

    function poolTokens(bytes32 _pid) external view returns (IERC20 token0, IERC20 token1) {
        return _poolTokens(_pid);
    }

    // Pool Price
    function _poolPrice(bytes32 _pid) internal view virtual returns (uint256 price) {
        (uint160 priceX96,) = _poolState(_pid);
        price = priceX96.priceX96ToPrice();
    }

    function poolPrice(bytes32 _pid) external view returns (uint256 price) {
        return _poolPrice(_pid);
    }

    // Pool State
    function _poolState(bytes32 _pid) internal view virtual returns (uint160 priceX96, int24 tick);

    function poolState(bytes32 _pid) external view returns (uint160 priceX96, int24 tick) {
        return _poolState(_pid);
    }

    // Safe Pool State
    function _safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation);

    function safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation)
    {
        return _safePoolState(_pid, _lookback, _maxDeviationBp);
    }

    // Safe Pool Price
    function _safePoolPrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        returns (uint256 price)
    {
        (uint160 priceX96Ret,,, bool isStaleRet,) = _safePoolState(_pid, _lookback, _maxDeviationBp);
        if (isStaleRet) revert Errors.StalePrice();
        price = priceX96Ret.priceX96ToPrice();
    }

    function safePoolPrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (uint256 price)
    {
        return _safePoolPrice(_pid, _lookback, _maxDeviationBp);
    }

    // Is Pool Price Stale
    function _isPoolPriceStale(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        returns (bool isStale)
    {
        (,,, isStale,) = _safePoolState(_pid, _lookback, _maxDeviationBp);
    }

    function isPoolPriceStale(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (bool isStale)
    {
        return _isPoolPriceStale(_pid, _lookback, _maxDeviationBp);
    }

    // Range Position Info
    function _rangePositionInfo(Range calldata _range)
        internal
        view
        virtual
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    function rangePositionInfo(Range calldata _range)
        external
        view
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        return _rangePositionInfo(_range);
    }

    // Liquidity To Amounts Ticks
    function _liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        internal
        view
        virtual
        returns (uint256 amount0, uint256 amount1);

    function liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        return _liquidityToAmountsTicks(_pid, _lowerTick, _upperTick, _liquidityValue);
    }

    // Amounts To Liquidity
    function _amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) internal view virtual returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual);

    function amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) external view returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual) {
        return _amountsToLiquidity(_pid, _lowerTick, _upperTick, _amount0Desired, _amount1Desired);
    }

    // Liquidity Ratio 0
    function _liquidityRatio0(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        internal
        view
        virtual
        returns (uint256 ratio0)
    {
        (uint256 amount0_val, uint256 amount1_val) = _liquidityToAmountsTicks(_pid, _lowerTick, _upperTick, _liquidity);
        if (amount0_val + amount1_val == 0) return 0;
        return amount0_val.mulDivDown(M.PREC_BPS, amount0_val + amount1_val);
    }

    function liquidityRatio0(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        external
        view
        returns (uint256 ratio0)
    {
        return _liquidityRatio0(_pid, _lowerTick, _upperTick, _liquidity);
    }

    // Liquidity Ratio 1
    function _liquidityRatio1(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        internal
        view
        virtual
        returns (uint256 ratio1)
    {
        (uint256 amount0_val, uint256 amount1_val) = _liquidityToAmountsTicks(_pid, _lowerTick, _upperTick, _liquidity);
        if (amount0_val + amount1_val == 0) return 0;
        return amount1_val.mulDivDown(M.PREC_BPS, amount0_val + amount1_val);
    }

    function liquidityRatio1(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        external
        view
        returns (uint256 ratio1)
    {
        return _liquidityRatio1(_pid, _lowerTick, _upperTick, _liquidity);
    }

    // LP Price 0 At Price
    function _lpPrice0AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        internal
        view
        virtual
        returns (uint256 lpPrice)
    {
        (uint256 amount0_val, uint256 amount1_val) =
            _liquidityToAmountsTicks(_pid, _lowerTick, _upperTick, uint128(M.WAD));
        if (_price == 0) {
            if (amount1_val > 0) revert Errors.InvalidParameter();
            return amount0_val;
        }
        lpPrice = amount0_val + amount1_val.mulDivDown(M.WAD, _price);
    }

    function lpPrice0AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        external
        view
        returns (uint256 lpPrice)
    {
        return _lpPrice0AtPrice(_pid, _lowerTick, _upperTick, _price);
    }

    // LP Price 1 At Price
    function _lpPrice1AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        internal
        view
        virtual
        returns (uint256 lpPrice)
    {
        (uint256 amount0_val, uint256 amount1_val) =
            _liquidityToAmountsTicks(_pid, _lowerTick, _upperTick, uint128(M.WAD));
        if (M.WAD == 0) revert Errors.InvalidParameter();
        lpPrice = amount1_val + amount0_val.mulDivDown(_price, M.WAD);
    }

    function lpPrice1AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        external
        view
        returns (uint256 lpPrice)
    {
        return _lpPrice1AtPrice(_pid, _lowerTick, _upperTick, _price);
    }

    // LP Price 0
    function _lpPrice0(bytes32 _pid, int24 _lowerTick, int24 _upperTick)
        internal
        view
        virtual
        returns (uint256 lpPrice)
    {
        uint256 currentPrice = _poolPrice(_pid);
        return _lpPrice0AtPrice(_pid, _lowerTick, _upperTick, currentPrice);
    }

    function lpPrice0(bytes32 _pid, int24 _lowerTick, int24 _upperTick) external view returns (uint256 lpPrice) {
        return _lpPrice0(_pid, _lowerTick, _upperTick);
    }

    // LP Price 1
    function _lpPrice1(bytes32 _pid, int24 _lowerTick, int24 _upperTick)
        internal
        view
        virtual
        returns (uint256 lpPrice)
    {
        uint256 currentPrice = _poolPrice(_pid);
        return _lpPrice1AtPrice(_pid, _lowerTick, _upperTick, currentPrice);
    }

    function lpPrice1(bytes32 _pid, int24 _lowerTick, int24 _upperTick) external view returns (uint256 lpPrice) {
        return _lpPrice1(_pid, _lowerTick, _upperTick);
    }

    // Collect Range Fees
    function _collectRangeFees(Range calldata _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        returns (uint256 collectedFee0, uint256 collectedFee1);

    function collectRangeFees(Range calldata _range, address _recipient, bytes calldata _callbackData)
        external
        onlyTreasury
        returns (uint256 collectedFee0, uint256 collectedFee1)
    {
        return _collectRangeFees(_range, _recipient, _callbackData);
    }

    function _poolTickSpacing(bytes32 _pid) internal view virtual returns (int24);

    function poolTickSpacing(bytes32 _pid) external view returns (int24) {
        return _poolTickSpacing(_pid);
    }

    function _validateTickSpacing(bytes32 _pid, int24 _lowerTick, int24 _upperTick)
        internal
        view
        virtual
        returns (bool)
    {
        return _poolTickSpacing(_pid).validateTickSpacing(_lowerTick, _upperTick);
    }

    function validateTickSpacing(bytes32 _pid, int24 _lowerTick, int24 _upperTick) external view returns (bool) {
        return _validateTickSpacing(_pid, _lowerTick, _upperTick);
    }

    function _checkStalePrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp) internal view virtual {
        if (_isPoolPriceStale(_pid, _lookback, _maxDeviationBp)) {
            revert Errors.StalePrice();
        }
    }

    function _validatePoolTokens(bytes32 _pid, IERC20 _expectedToken0, IERC20 _expectedToken1) internal view virtual {
        (IERC20 actualToken0, IERC20 actualToken1) = _poolTokens(_pid);
        DU.checkMatchTokens(
            address(actualToken0), address(actualToken1), address(_expectedToken0), address(_expectedToken1)
        );
    }

    function validatePoolTokens(bytes32 _pid, IERC20 _expectedToken0, IERC20 _expectedToken1) external view {
        return _validatePoolTokens(_pid, _expectedToken0, _expectedToken1);
    }

    // Missing decimals function
    function decimals() external view virtual returns (uint8) {
        return 18; // Default to 18 decimals, can be overridden in specific adapters
    }

    // Missing liquidityToAmounts function (wrapper for liquidityToAmountsTicks)
    function liquidityToAmounts(bytes32 /* _rid */, uint128 /* _liquidityValue */)
        external
        view
        virtual
        returns (uint256 /* amount0 */, uint256 /* amount1 */)
    {
        // This is a simplified implementation - in a real system, _rid would need to be decoded
        // to extract poolId, lowerTick, and upperTick. For now, this will need to be implemented
        // per adapter based on how _rid is structured.
        revert Errors.NotInitialized();
    }

    // Preview Burn Range
    function _previewBurnRange(Range calldata _range, uint128 _liquidityToPreview)
        internal
        view
        virtual
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1);

    function previewBurnRange(Range calldata _range, uint128 _liquidityToPreview)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        return _previewBurnRange(_range, _liquidityToPreview);
    }

    // Mint Range
    function _mintRange(Range calldata _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        returns (bytes32 positionId, uint128 liquidityMinted, uint256 amount0, uint256 amount1);

    function mintRange(Range calldata _range, address _recipient, bytes calldata _callbackData)
        external
        onlyDiamond
        returns (bytes32 positionId, uint128 liquidityMinted, uint256 amount0, uint256 amount1)
    {
        return _mintRange(_range, _recipient, _callbackData);
    }

    // Burn Range
    function _burnRange(Range calldata _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1);

    function burnRange(Range calldata _range, address _recipient, bytes calldata _callbackData)
        external
        onlyDiamond
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        return _burnRange(_range, _recipient, _callbackData);
    }
}
