// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ALMVault, Range, ErrorType, DEX, PoolInfo} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {DEXAdapterFacet} from "@facets/abstract/DEXAdapterFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title V3 DEX Adapter Base - Abstract base for Uniswap V3-style DEX adapters
 * @copyright 2025
 * @notice Defines the interface and common logic for V3 DEX interactions
 * @dev Provides reusable V3-specific functions (mintRange, burnRange, collectFees)
- Converts ticks and liquidity units via `LibDEXMaths`
- Ensures token ordering and safety checks
- Inherited by specific adapters: UniV3, CakeV3, ThenaV3

 * @author BTR Team
 */

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title V3 DEX Adapter Base - Abstract base for Uniswap V3-style DEX adapters
 * @copyright 2025
 * @notice Defines the interface and common logic for V3 DEX interactions
 * @dev Provides reusable V3-specific functions (mintRange, burnRange, collectFees) - Converts ticks and liquidity units via `LibDEXMaths` - Ensures token ordering and safety checks - Inherited by specific adapters: UniV3, CakeV3, ThenaV3

 * @author BTR Team
 */

abstract contract V3AdapterFacet is DEXAdapterFacet {
    using SafeERC20 for IERC20;
    using M for uint256;
    using U for uint32;
    using U for bytes32;
    using C for uint256;
    using C for bytes32;
    using DM for int24;
    using DM for uint160;

    function _poolTokens(IUniV3Pool _pool) internal view virtual returns (IERC20 token0, IERC20 token1) {
        return (IERC20(_pool.token0()), IERC20(_pool.token1()));
    }

    function poolTokens(bytes32 _pid) public view override returns (IERC20 token0, IERC20 token1) {
        return _poolTokens(IUniV3Pool(_pid.toAddress()));
    }

    function _poolTickSpacing(bytes32 _pid) internal view override returns (int24) {
        return IUniV3Pool(_pid.toAddress()).tickSpacing();
    }

    function _validateTickSpacing(Range memory _range) internal view override returns (bool) {
        return _poolTickSpacing(_range.poolId).validateTickSpacing(_range.lowerTick, _range.upperTick);
    }

    function _poolState(address _pool) internal view virtual returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IUniV3Pool(_pool).slot0();
    }

    function poolState(bytes32 _pid) public view override returns (uint160 priceX96, int24 tick) {
        return _poolState(_pid.toAddress());
    }

    function _position(address _pool, bytes32 _positionId)
        internal
        view
        virtual
        returns (uint128 liquidity, uint128 fee0, uint128 fee1)
    {
        (liquidity,,, fee0, fee1) = IUniV3Pool(_pool).positions(keccak256(abi.encodePacked(address(this), _positionId)));
    }

    function _positionInfo(address _pool, bytes32 _positionId, int24 _tickLower, int24 _tickUpper)
        internal
        view
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint128 fee0, uint128 fee1)
    {
        (liquidity, fee0, fee1) = _position(_pool, _positionId);
        (, int24 currentTick) = _poolState(_pool);
        (amount0, amount1) = DM.liquidityToAmountsTickV3(currentTick, _tickLower, _tickUpper, liquidity);
    }

    function rangePositionInfo(bytes32 _rid)
        public
        view
        override
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        Range storage range = _rid.range();
        return _positionInfo(range.poolId.toAddress(), range.positionId, range.lowerTick, range.upperTick);
    }

    function liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _liquidity)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (, int24 currentTick) = _poolState(_pid.toAddress());
        return DM.liquidityToAmountsTickV3(currentTick, _lowerTick, _upperTick, uint128(_liquidity));
    }

    function liquidityToAmounts(bytes32 _rid, uint256 _liquidity)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        Range storage r = _rid.range();
        (amount0, amount1) = liquidityToAmountsTicks(r.poolId, r.lowerTick, r.upperTick, _liquidity);
    }

    // Internal helper for computing liquidity from token amounts given tick range
    function amountsToLiquidityTicks(
        bytes32 _pid,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1
    ) public view returns (uint128 liquidity) {
        (uint160 priceX96,) = _poolState(_pid.toAddress());
        return priceX96.amountsToLiquidityPriceX96V3(
            _tickLower.tickToPriceX96V3(), _tickUpper.tickToPriceX96V3(), _amount0, _amount1
        );
    }

    function amountsToLiquiditySqrt(bytes32 _rid, uint256 _amount0, uint256 _amount1)
        public
        view
        override
        returns (uint128 liquidity)
    {
        Range storage r = _rid.range();
        return amountsToLiquidityTicks(r.poolId, r.lowerTick, r.upperTick, _amount0, _amount1);
    }

    function amountsToLiquidity(bytes32 _rid, uint256 _amount0, uint256 _amount1)
        public
        view
        override
        returns (uint128 liquidity)
    {
        Range storage r = _rid.range();
        return amountsToLiquidityTicks(r.poolId, r.lowerTick, r.upperTick, _amount0, _amount1);
    }

    function _mintPosition(address _pool, int24 _tickLower, int24 _tickUpper, uint128 _liquidity)
        internal
        virtual
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) =
            IUniV3Pool(_pool).mint(address(this), _tickLower, _tickUpper, _liquidity, abi.encode(_pool));
    }

    function _mintRange(Range storage _range)
        internal
        override
        returns (uint256 mintedLiquidity, uint256 amount0, uint256 amount1)
    {
        address v3Pool = _range.poolId.toAddress();

        // New range = new position
        if (_range.positionId == bytes32(0)) {
            _range.positionId = bytes32(U.positionId(_range.lowerTick, _range.upperTick));
        }

        // Get liquidity from position
        (uint128 liq128,,) = _position(v3Pool, _range.positionId);

        // Allow increase only
        if (uint256(liq128) >= _range.liquidity) {
            revert Errors.Exceeds(uint256(liq128), _range.liquidity);
        }

        (IERC20 token0, IERC20 token1) = _poolTokens(v3Pool);

        // Approve tokens vault->pool
        token0.approve(v3Pool, type(uint256).max);
        token1.approve(v3Pool, type(uint256).max);

        mintedLiquidity = _range.liquidity - uint256(liq128);
        (amount0, amount1) = _mintPosition(v3Pool, _range.lowerTick, _range.upperTick, uint128(mintedLiquidity));

        // Revoke approvals pool->vault (after mint callback)
        token0.approve(v3Pool, 0);
        token1.approve(v3Pool, 0);
    }

    function _mintCallback(uint256 _owed0, uint256 _owed1, bytes calldata _data) internal {
        address pool = abi.decode(_data, (address));
        if (msg.sender != pool) {
            revert Errors.Unauthorized(ErrorType.CONTRACT);
        }

        (IERC20 token0, IERC20 token1) = _poolTokens(IUniV3Pool(pool));

        // Transfer owed tokens to the pool
        if (_owed0 > 0) {
            token0.safeTransfer(msg.sender, _owed0);
        }
        if (_owed1 > 0) {
            token1.safeTransfer(msg.sender, _owed1);
        }
    }

    function _burnPosition(address _pool, int24 _tickLower, int24 _tickUpper, uint128 _liquidity)
        internal
        virtual
        returns (uint256 amount0, uint256 amount1)
    {
        // Burn position to release tokens
        (amount0, amount1) = IUniV3Pool(_pool).burn(_tickLower, _tickUpper, _liquidity);
    }

    function _burnRange(Range storage _range)
        internal
        override
        returns (uint256 burntLiquidity, uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        address pool = _range.poolId.toAddress();

        // New position = new range
        if (_range.positionId == bytes32(0)) {
            revert Errors.NotFound(ErrorType.RANGE);
        }

        // Get liquidity from position
        (uint128 liq128,,) = _position(pool, _range.positionId);
        burntLiquidity = uint256(liq128);

        // burn position
        (amount0, amount1) = _burnPosition(pool, _range.lowerTick, _range.upperTick, liq128);

        // Collect tokens from burnt liquidity and fees
        (uint256 collected0, uint256 collected1) = _collectPosition(pool, _range.lowerTick, _range.upperTick);

        // Calculate LP fee amounts
        lpFee0 = collected0.subMax0(amount0);
        lpFee1 = collected1.subMax0(amount1);

        // update range liquidity
        _range.liquidity = 0;
    }

    function _collectPosition(address _pool, int24 _tickLower, int24 _tickUpper)
        internal
        virtual
        returns (uint256 collected0, uint256 collected1)
    {
        return IUniV3Pool(_pool).collect(address(this), _tickLower, _tickUpper, type(uint128).max, type(uint128).max);
    }

    function collectRangeFees(bytes32 _rid) public override returns (uint256 collected0, uint256 collected1) {
        Range storage r = _rid.range();
        return _collectPosition(r.poolId.toAddress(), r.lowerTick, r.upperTick);
    }

    function _observe(address _pool, uint32[] memory _secondsAgos)
        internal
        view
        virtual
        returns (int56[] memory tickCumulatives, uint160[] memory intervalSecondsX128)
    {
        return IUniV3Pool(_pool).observe(_secondsAgos);
    }

    function _consult(address _pool, uint32 _lookback)
        internal
        view
        virtual
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = _lookback;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory intervalSecondsX128) = _observe(_pool, secondsAgos);

        // Calculate arithmetic mean tick
        arithmeticMeanTick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(_lookback)));

        // Calculate harmonic mean liquidity
        uint160 secondsPerLiquidityDelta = intervalSecondsX128[1] - intervalSecondsX128[0];
        if (secondsPerLiquidityDelta > 0) {
            harmonicMeanLiquidity = uint128((uint256(_lookback) << 128) / (uint256(secondsPerLiquidityDelta) + 1));
        }
    }

    function safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        public
        view
        override
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation)
    {
        return _safePoolState(_pid.toAddress(), _lookback, _maxDeviationBp);
    }

    function _safePoolState(address _pool, uint32 _lookback, uint256 _maxDeviation)
        internal
        view
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation)
    {
        (priceX96, tick) = _poolState(_pool); // current price and tick
        (int24 arithmeticMeanTick,) = _consult(_pool, _lookback); // twap
        twapPriceX96 = arithmeticMeanTick.tickToPriceX96V3();
        (isStale, deviation) = DM.deviationState(priceX96, twapPriceX96, _maxDeviation); // deviation
    }

    function _poolTokens(address _pool) internal view virtual returns (IERC20 token0, IERC20 token1) {
        return (IERC20(IUniV3Pool(_pool).token0()), IERC20(IUniV3Pool(_pool).token1()));
    }
}
