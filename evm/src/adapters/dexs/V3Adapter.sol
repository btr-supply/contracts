// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {Range} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {DEXAdapter} from "@dexs/DEXAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title V3 Adapter Base - Base contract for V3-style DEX adapters
 * @copyright 2025
 * @notice Provides shared V3 functionality for adapter facets
 * @dev Common logic for V3-based DEX integrations
 * @author BTR Team
 */

abstract contract V3Adapter is DEXAdapter {
    using SafeERC20 for IERC20;
    using C for uint256;
    using C for bytes32;
    using M for uint256;
    using DM for int24;
    using DM for uint160;

    constructor(address _diamondAddress) DEXAdapter(_diamondAddress) {}

    function _poolTokens(address _pool) internal view virtual returns (IERC20 token0, IERC20 token1) {
        return (IERC20(IUniV3Pool(_pool).token0()), IERC20(IUniV3Pool(_pool).token1()));
    }

    function _poolTokens(bytes32 _pid) internal view virtual override returns (IERC20 token0, IERC20 token1) {
        return _poolTokens(_pid.toAddress());
    }

    function _poolTickSpacing(bytes32 _pid) internal view virtual override returns (int24) {
        return IUniV3Pool(_pid.toAddress()).tickSpacing();
    }

    function _poolState(address _pool) internal view virtual returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IUniV3Pool(_pool).slot0();
    }

    function _poolState(bytes32 _pid) internal view virtual override returns (uint160 priceX96, int24 tick) {
        return _poolState(_pid.toAddress());
    }

    function _getPosition(address _pool, bytes32 _positionKey)
        internal
        view
        virtual
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        // This matches how Uniswap V3 NonfungiblePositionManager constructs the key for `positions` mapping.
        // The caller (e.g. LibALMBase) would be responsible for generating this key correctly.
        (liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1) =
            IUniV3Pool(_pool).positions(_positionKey);
    }

    function _rangePositionInfo(Range memory _range)
        internal
        view
        virtual
        override
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        address pool = _range.poolId.toAddress();
        // For fees, V3 requires calling `collect` with 0 amounts or observing `feeGrowthInside` and `tick.feeGrowthOutside`.
        // A simple way to get pending fees is to simulate a collect. Some pools might not expose this easily.
        // The `tokensOwed0` and `tokensOwed1` from `_getPosition` are the uncollected fees.
        (uint128 posLiquidity,,, uint128 uncollectedFee0, uint128 uncollectedFee1) =
            _getPosition(pool, _range.positionId);
        liquidity = posLiquidity;
        fee0 = uncollectedFee0;
        fee1 = uncollectedFee1;

        (, int24 currentTick) = _poolState(pool);
        (amount0, amount1) = DM.liquidityToAmountsTickV3(currentTick, _range.lowerTick, _range.upperTick, liquidity);
    }

    function _liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (, int24 currentTick) = _poolState(_pid.toAddress()); // Get current tick from pool state
        return DM.liquidityToAmountsTickV3(currentTick, _lowerTick, _upperTick, _liquidityValue);
    }

    function _amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) internal view virtual override returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual) {
        (uint160 priceX96,) = _poolState(_pid); // Use overridden _poolState
        uint160 sqrtRatioAX96 = _lowerTick.tickToPriceX96V3();
        uint160 sqrtRatioBX96 = _upperTick.tickToPriceX96V3();

        liquidity = DM.getLiquidityForAmounts(priceX96, sqrtRatioAX96, sqrtRatioBX96, _amount0Desired, _amount1Desired);

        // Recalculate actual amounts for the derived liquidity
        // This logic is from UniswapV3 LiquidityAmounts.getAmountsForLiquidity
        if (priceX96 <= sqrtRatioAX96) {
            // current price is below the range
            amount0Actual = DM.getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
            amount1Actual = 0;
        } else if (priceX96 < sqrtRatioBX96) {
            // current price is inside the range
            amount0Actual = DM.getAmount0ForLiquidity(priceX96, sqrtRatioBX96, liquidity);
            amount1Actual = DM.getAmount1ForLiquidity(sqrtRatioAX96, priceX96, liquidity);
        } else {
            // current price is above the range
            amount0Actual = 0;
            amount1Actual = DM.getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }

    function _mintPosition(
        address _pool,
        address _recipientForPool, // Who receives the tokens in callback
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        bytes calldata _callbackDataForPool
    ) internal virtual returns (uint256 amount0, uint256 amount1) {
        // The recipient must have approved this adapter contract for the tokens to be pulled by the pool.
        (amount0, amount1) =
            IUniV3Pool(_pool).mint(_recipientForPool, _tickLower, _tickUpper, _liquidity, _callbackDataForPool);
    }

    function _mintRange(
        Range memory _range,
        address _recipient,
        bytes calldata _callbackData // Expected to be abi.encode(pool, payerAddress (likely _recipient))
    ) internal virtual override returns (bytes32 positionId, uint128 liquidityMinted, uint256 spent0, uint256 spent1) {
        address pool = _range.poolId.toAddress();
        (IERC20 token0, IERC20 token1) = _poolTokens(pool); // Use overridden _poolTokens helper

        // The pool will pull tokens from the `payerAddress` specified in the `_callbackData` during the callback.
        // That `payerAddress` (expected to be `msg.sender`) must approve this adapter contract.
        // This adapter approves the pool to pull from itself (address(this)) if address(this) is the recipient in mint.
        // If using callback: address(this) is recipient in mint, callback makes this contract pay using tokens from payer.
        // The V3 pool's mint function is called with `address(this)` as the recipient to trigger the callback to this contract.

        // Approve tokens from this adapter to the pool.
        // This adapter must have the tokens (transferred by `payerAddress` or `payerAddress` approved this adapter).
        token0.safeApprove(pool, type(uint256).max);
        token1.safeApprove(pool, type(uint256).max);

        (spent0, spent1) = _mintPosition(
            pool,
            address(this), // Recipient for pool.mint is this contract to trigger callback
            _range.lowerTick,
            _range.upperTick,
            _range.liquidity, // Desired liquidity from Range struct
            _callbackData // Pass through callbackData, expected: abi.encode(pool, msg.sender)
        );
        liquidityMinted = _range.liquidity; // Assume mint is successful for the desired liquidity.

        // Revoke approvals after mint
        token0.safeApprove(pool, 0);
        token1.safeApprove(pool, 0);

        // Generate a positionId, common for V3 NonfungiblePositionManager.
        // BTRDiamond is responsible for ensuring msg.sender matches the payer in _callbackData if that's the convention.
        positionId = keccak256(abi.encodePacked(_recipient, _range.lowerTick, _range.upperTick));
        // NB: Slippage protection should be handled by the caller
    }

    function uniswapV3MintCallback(uint256 _amount0Owed, uint256 _amount1Owed, bytes calldata _data) external virtual {
        (address poolFromData, address payerAddress) = abi.decode(_data, (address, address));

        // msg.sender should be the pool that this callback is registered for.
        // The poolFromData is for an additional check if needed.
        if (msg.sender == address(0)) revert Errors.ZeroAddress(); // Should be pool
        // if (msg.sender != poolFromData) revert Errors.InvalidCaller(); // Optional check

        (IERC20 token0, IERC20 token1) = _poolTokens(msg.sender); // Use msg.sender as pool address

        if (_amount0Owed > 0) {
            token0.safeTransferFrom(payerAddress, msg.sender, _amount0Owed); // Transfer from payer to pool
        }
        if (_amount1Owed > 0) {
            token1.safeTransferFrom(payerAddress, msg.sender, _amount1Owed); // Transfer from payer to pool
        }
    }

    function _burnPosition(address _pool, int24 _tickLower, int24 _tickUpper, uint128 _liquidity)
        internal
        virtual
        returns (uint256 amount0, uint256 amount1)
    {
        // For V3, burn() is typically called by the owner of the NFT position.
        // If this adapter contract owns the NFT (e.g. minted with address(this) as recipient), it can call burn.
        // The tokens from burn are sent to msg.sender of the burn() call.
        // Here, we assume this adapter contract is making the call.
        return IUniV3Pool(_pool).burn(_tickLower, _tickUpper, _liquidity);
    }

    function _burnRange(
        Range memory _range,
        address _recipient,
        bytes calldata _callbackData // Callback data for collect, if applicable
    )
        internal
        virtual
        override
        returns (uint256 amount0Burnt, uint256 amount1Burnt, uint256 fee0Collected, uint256 fee1Collected)
    {
        address pool = _range.poolId.toAddress();

        // Burn position: tokens are credited to this contract (msg.sender of burn).
        (amount0Burnt, amount1Burnt) = _burnPosition(pool, _range.lowerTick, _range.upperTick, _range.liquidity);

        // Collect tokens (base amounts from burn + fees).
        // The `collect` function in V3 sends tokens to the specified recipient.
        // For V3, the _range.positionId is not directly used by pool.collect, it uses owner+ticks implicitly.
        // However, _collectPosition helper might use _range.positionId if it needs to lookup something first.
        // The _callbackData is passed to _collectPosition.
        (uint256 total0Collected, uint256 total1Collected) = _collectPosition(
            pool,
            _recipient,
            _range.lowerTick,
            _range.upperTick,
            type(uint128).max, // Collect all available token0
            type(uint128).max, // Collect all available token1
            _callbackData // Pass through callbackData
        );

        // The amounts returned by `collect` are total (base + fees).
        // Fees are total_collected - principal_from_burn.
        fee0Collected = total0Collected.subMax0(amount0Burnt);
        fee1Collected = total1Collected.subMax0(amount1Burnt);

        // NB: Slippage protection should be handled by the caller
    }

    function _collectPosition(
        address _pool,
        address _recipientForCollect,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _amount0Max,
        uint128 _amount1Max,
        bytes calldata _callbackDataForCollect // For V3, not directly used by pool.collect
    ) internal virtual returns (uint256 collected0, uint256 collected1) {
        // _callbackDataForCollect is not used by IUniV3Pool.collect. It might be used if this adapter needs to react.
        // The recipient of the collect call is directly specified.
        // This assumes that the caller (this adapter) has the rights to collect for the position
        // (e.g., it's the owner of the V3 NFT or approved).
        return IUniV3Pool(_pool).collect(_recipientForCollect, _tickLower, _tickUpper, _amount0Max, _amount1Max);
    }

    function _collectRangeFees(Range memory _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        override
        returns (uint256 collectedFee0, uint256 collectedFee1)
    {
        // For V3, `collect` withdraws all owed tokens (base + fees) for a position.
        // The _range.positionId might be used internally if this adapter needs to map it to an owner for the pool,
        // but V3 `collect` itself takes recipient, lowerTick, upperTick.
        // We assume this adapter is authorized to collect for the position defined by _range's implicit owner and ticks.
        (collectedFee0, collectedFee1) = _collectPosition(
            _range.poolId.toAddress(),
            _recipient,
            _range.lowerTick,
            _range.upperTick,
            type(uint128).max, // Collect all available token0 fees
            type(uint128).max, // Collect all available token1 fees
            _callbackData // Pass through callbackData
        );
    }

    function _observe(address _pool, uint32[] memory _secondsAgos)
        internal
        view
        virtual
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128)
    {
        return IUniV3Pool(_pool).observe(_secondsAgos);
    }

    function _consult(address _pool, uint32 _lookback) internal view virtual returns (int24 arithmeticMeanTick) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = _lookback;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = _observe(_pool, secondsAgos);

        arithmeticMeanTick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(_lookback)));
    }

    function _safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        override
        returns (
            uint160 priceX96,
            int24 tick, // current tick also returned
            uint160 twapPriceX96,
            bool isStale,
            uint256 deviation
        )
    {
        address pool = _pid.toAddress();
        (priceX96, tick) = _poolState(pool); // current price and tick, uses overridden _poolState
        int24 arithmeticMeanTick = _consult(pool, _lookback); // twap tick
        twapPriceX96 = arithmeticMeanTick.tickToPriceX96V3();
        (isStale, deviation) = DM.deviationState(priceX96, twapPriceX96, _maxDeviationBp);
    }

    function _previewBurnRange(Range memory _range, uint128 _liquidityToPreview)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        address pool = _range.poolId.toAddress();
        (, int24 currentTick) = _poolState(pool); // uses overridden _poolState
        (amount0, amount1) =
            DM.liquidityToAmountsTickV3(currentTick, _range.lowerTick, _range.upperTick, _liquidityToPreview);

        // To preview fees, we need to look at the position's current `tokensOwed`.
        // This requires knowing the specific position via _range.positionId.
        if (_range.positionId != bytes32(0)) {
            (,,, uint128 owed0, uint128 owed1) = _getPosition(pool, _range.positionId);
            lpFee0 = owed0;
            lpFee1 = owed1;
        } else {
            // If no positionId, cannot determine specific fees for *this* potential position.
            lpFee0 = 0;
            lpFee1 = 0;
        }
    }
}
