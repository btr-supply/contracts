// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ALMVault, Range, ErrorType} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NonReentrantFacet} from "@facets/abstract/NonReentrantFacet.sol";
import {PausableFacet} from "@facets/abstract/PausableFacet.sol";
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
 * @title DEX Adapter - Base contract for DEX integrations
 * @copyright 2025
 * @notice Abstract base contract for decentralized exchange integrations
 * @dev Core base for DEX adapter facets
- Defines pool registration (`setPoolInfo`), swap routing and safety checks
- Used by all V3 adapter facets (Uniswap, PancakeSwap, Thena, etc.)
- Key modifiers: `onlyAdmin`, internal `nonReentrant` guards

 * @author BTR Team
 */

abstract contract DEXAdapterFacet is PermissionedFacet, NonReentrantFacet, PausableFacet {
    using SafeERC20 for IERC20;
    using C for uint256;
    using M for uint256;
    using U for uint32;
    using U for bytes32;
    using DM for int24;
    using DM for uint160;

    function poolTokens(bytes32 _pid) public view virtual returns (IERC20 token0, IERC20 token1);

    function _validatePoolTokens(uint32 _vid, address _pool) internal view {
        ALMVault storage vault = _vid.vault();
        (IERC20 token0, IERC20 token1) = poolTokens(bytes32(uint256(uint160(_pool))));

        // Ensure tokens match vault configuration
        if (token0 != vault.token0 || token1 != vault.token1) {
            // NB: the pool tokens might be inverted vs the vault configuration
            revert Errors.Unauthorized(ErrorType.TOKEN);
        }
    }

    function _poolTickSpacing(bytes32 _pid) internal view virtual returns (int24);

    function _validateTickSpacing(Range memory _range) internal view virtual returns (bool);

    function poolState(bytes32 _pid) public view virtual returns (uint160 priceX96, int24 tick);

    function safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        public
        view
        virtual
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation);

    function poolPrice(bytes32 _pid) public view virtual returns (uint256 _price) {
        (uint160 priceX96,) = poolState(_pid);
        _price = priceX96.priceX96ToPrice();
    }

    function safePoolPrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        public
        view
        virtual
        returns (uint256 _price)
    {
        (uint160 priceX96,, /* uint160 twapPriceX96 */, bool isStale, /* uint256 deviation */ ) =
            safePoolState(_pid, _lookback, _maxDeviationBp);
        if (isStale) revert Errors.StalePrice();
        _price = priceX96.priceX96ToPrice();
    }

    function rangePositionInfo(bytes32 _rid)
        public
        view
        virtual
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    function liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _liquidity)
        public
        view
        virtual
        returns (uint256 amount0, uint256 amount1);

    function liquidityToAmounts(bytes32 _rid, uint256 _liquidity)
        public
        view
        virtual
        returns (uint256 amount0, uint256 amount1);

    function amountsToLiquiditySqrt(bytes32 _rid, uint256 _amount0, uint256 _amount1)
        public
        view
        virtual
        returns (uint128 liquidity);

    function amountsToLiquidity(bytes32 _rid, uint256 _amount0, uint256 _amount1)
        public
        view
        virtual
        returns (uint128 liquidity);

    function liquidityRatio0(bytes32 _rid) public view returns (uint256) {
        (uint256 amount0, uint256 amount1) = liquidityToAmounts(_rid, M.PREC_BPS);
        return amount0.divDown(amount1 + amount0);
    }

    function liquidityRatio1(bytes32 _rid) public view returns (uint256) {
        (uint256 amount0, uint256 amount1) = liquidityToAmounts(_rid, M.PREC_BPS);
        return amount1.divDown(amount1 + amount0);
    }

    function _mintRange(Range storage _range)
        internal
        virtual
        returns (uint256 mintedLiquidity, uint256 amount0, uint256 amount1);

    function mintRange(bytes32 _rid)
        external
        virtual
        returns (uint256 mintedLiquidity, uint256 amount0, uint256 amount1)
    {
        (mintedLiquidity, amount0, amount1) = _mintRange(_rid.range());
        emit Events.RangeMinted(_rid, mintedLiquidity, amount0, amount1);
    }

    function _burnRange(Range storage _range)
        internal
        virtual
        returns (uint256 liquidity, uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1);

    function burnRange(bytes32 _rid)
        external
        virtual
        returns (uint256 liquidity, uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        (liquidity, amount0, amount1, lpFee0, lpFee1) = _burnRange(_rid.range());
        emit Events.RangeBurnt(_rid, liquidity, amount0, amount1, lpFee0, lpFee1);
    }

    function previewBurnRange(bytes32 _rid)
        public
        view
        virtual
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        // Default implementation that can be overridden by specific adapters
        Range storage range = _rid.range();

        // If range has no liquidity, return zeroes
        if (range.liquidity == 0) return (0, 0, 0, 0);

        // Get position details
        (uint128 liquidity, uint256 pos0, uint256 pos1, uint256 fee0, uint256 fee1) = rangePositionInfo(_rid);
        (lpFee0, lpFee1) = (fee0, fee1);

        // Calculate token amounts proportionally if there's a difference between range.liquidity and total ALM liquidity
        if (liquidity > 0 && range.liquidity <= liquidity) {
            amount0 = pos0.mulDivDown(range.liquidity, liquidity); // Scale position amount by the ratio of range.liquidity to liquidity
            amount1 = pos1.mulDivDown(range.liquidity, liquidity);
        } else {
            amount0 = pos0; // Cap at the position's amount
            amount1 = pos1;
        }
    }

    function collectRangeFees(bytes32 _rid) public virtual returns (uint256 fee0, uint256 fee1);

    function isPoolPriceStale(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        public
        view
        virtual
        returns (bool isStale)
    {
        (,,, isStale,) = safePoolState(_pid, _lookback, _maxDeviationBp);
    }

    function _checkStalePrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp) internal view {
        if (isPoolPriceStale(_pid, _lookback, _maxDeviationBp)) {
            revert Errors.StalePrice();
        }
    }

    function _lpPrice0AtPrice(Range storage _r, uint256 _price) internal view returns (uint256 lpPrice) {
        (uint256 amount0, uint256 amount1) = liquidityToAmounts(_r.id, M.WAD);
        lpPrice = amount0 + amount1.mulDivDown(M.WAD, _price);
    }

    function _lpPrice1AtPrice(Range storage _r, uint256 _price) internal view returns (uint256 lpPrice) {
        (uint256 amount0, uint256 amount1) = liquidityToAmounts(_r.id, M.WAD);
        lpPrice = amount1 + amount0.mulDivDown(_price, M.WAD);
    }

    function lpPrice0AtPrice(bytes32 _rid, uint256 _price) public view returns (uint256 lpPrice) {
        lpPrice = _lpPrice0AtPrice(_rid.range(), _price);
    }

    function lpPrice1AtPrice(bytes32 _rid, uint256 _price) public view returns (uint256 lpPrice) {
        lpPrice = _lpPrice1AtPrice(_rid.range(), _price);
    }

    function lpPrice0(bytes32 _rid) public view returns (uint256 lpPrice) {
        Range storage r = _rid.range();
        lpPrice = _lpPrice0AtPrice(r, poolPrice(r.poolId));
    }

    function lpPrice1(bytes32 _rid) public view returns (uint256 lpPrice) {
        Range storage r = _rid.range();
        lpPrice = _lpPrice1AtPrice(r, poolPrice(r.poolId));
    }
}
