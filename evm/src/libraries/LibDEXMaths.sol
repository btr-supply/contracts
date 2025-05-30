// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibCast as C} from "@libraries/LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title DEX Maths Library - Mathematical functions for DEX interactions
 * @copyright 2025
 * @notice Provides calculations specific to DEX pools (e.g., tick math, price conversions)
 * @dev Provides price↔tick conversions and liquidity math (e.g., `sqrtToTick`)
- Used in `LibALM` and V3 adapters for accurate range calculations

 * @author BTR Team
 */

library LibDEXMaths {
    using C for uint256;
    using C for int256;
    using M for uint256;
    using M for uint160;

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;
    uint160 internal constant MIN_SQRT = 4295128739;
    uint160 internal constant MAX_SQRT = 1461446703485210103287273052203988822378723970342;

    function invertPriceX96(uint160 _priceX96) internal pure returns (uint160 invertedPriceX96) {
        return uint160(M.Q192 / _priceX96);
    }

    function priceX96ToPrice(uint160 priceX96) internal pure returns (uint256 price) {
        uint256 _X96 = uint256(priceX96);
        price = _X96.mulDivDown(_X96, M.Q192).mulDivDown(M.WAD, 1); // combines to: x^2 * 1e18 / 2^192
    }

    function priceToPriceX96(uint256 price) internal pure returns (uint160 priceX96) {
        uint256 priceX192 = price.mulDivDown(M.Q192, M.WAD); // Convert price to Q192: priceX192 = price * 2**192 / 1e18
        uint256 _X96 = priceX192.sqrt(); // Take integer sqrt of Q192 value to get Q64.96 result
        require(_X96 <= type(uint160).max); // Overflow check
        priceX96 = uint160(_X96);
    }

    function tickToPriceX96V3(int24 _tick) internal pure returns (uint160 priceX96) {
        unchecked {
            uint256 absTick = uint256(_tick < 0 ? -int256(_tick) : int256(_tick));
            require(absTick <= uint256(int256(MAX_TICK)));
            uint256 ratio =
                absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) {
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            }
            if (absTick & 0x4 != 0) {
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            }
            if (absTick & 0x8 != 0) {
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            }
            if (absTick & 0x10 != 0) {
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            }
            if (absTick & 0x20 != 0) {
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            }
            if (absTick & 0x40 != 0) {
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            }
            if (absTick & 0x80 != 0) {
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            }
            if (absTick & 0x100 != 0) {
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            }
            if (absTick & 0x200 != 0) {
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            }
            if (absTick & 0x400 != 0) {
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            }
            if (absTick & 0x800 != 0) {
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            }
            if (absTick & 0x1000 != 0) {
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            }
            if (absTick & 0x2000 != 0) {
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            }
            if (absTick & 0x4000 != 0) {
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            }
            if (absTick & 0x8000 != 0) {
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            }
            if (absTick & 0x10000 != 0) {
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            }
            if (absTick & 0x20000 != 0) {
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            }
            if (absTick & 0x40000 != 0) {
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            }
            if (absTick & 0x80000 != 0) {
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
            }

            if (_tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so sqrtToTick of the output price is always consistent
            priceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function priceX96ToTickV3(uint160 _priceX96) internal pure returns (int24 tick) {
        require(_priceX96 >= MIN_SQRT && _priceX96 < MAX_SQRT); // Max tick overflow check
        uint256 ratio = uint256(_priceX96) << 32;
        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 l2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            l2 := or(l2, shl(50, f))
        }

        int256 logSqrt10001 = l2 * 255738958999603826347141; // 128.128 number

        int24 lowTick = int24((logSqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 highTick = int24((logSqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = lowTick == highTick ? lowTick : tickToPriceX96V3(highTick) <= _priceX96 ? highTick : lowTick;
    }

    function liquidityToAmount0PriceX96V3(uint160 _priceX96A, uint160 _priceX96B, uint128 _liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        if (_priceX96A > _priceX96B) {
            (_priceX96A, _priceX96B) = (_priceX96B, _priceX96A);
        }

        return (uint256(_liquidity) * M.Q96 * (_priceX96B - _priceX96A)) / (_priceX96A * _priceX96B);
    }

    function liquidityToAmount1PriceX96V3(uint160 _priceX96A, uint160 _priceX96B, uint128 _liquidity)
        internal
        pure
        returns (uint256 amount1)
    {
        if (_priceX96A > _priceX96B) {
            (_priceX96A, _priceX96B) = (_priceX96B, _priceX96A);
        }

        return (uint256(_liquidity) * (_priceX96B - _priceX96A)) / M.Q96;
    }

    function amountsToLiquidityPriceX96V3(
        uint160 _priceX96,
        uint160 _priceX96A,
        uint160 _priceX96B,
        uint256 _amount0,
        uint256 _amount1
    ) internal pure returns (uint128 liquidity) {
        if (_priceX96A > _priceX96B) {
            (_priceX96A, _priceX96B) = (_priceX96B, _priceX96A);
        }

        if (_priceX96 <= _priceX96A) {
            liquidity = amount0ToLiquidityX96V3(_priceX96A, _priceX96B, _amount0);
        } else if (_priceX96 < _priceX96B) {
            uint128 liquidity0 = amount0ToLiquidityX96V3(_priceX96, _priceX96B, _amount0);
            uint128 liquidity1 = amount1ToLiquidityPriceX96V3(_priceX96A, _priceX96, _amount1);
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = amount1ToLiquidityPriceX96V3(_priceX96A, _priceX96B, _amount1);
        }
    }

    function amount0ToLiquidityX96V3(uint160 _priceX96A, uint160 _priceX96B, uint256 _amount0)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (_priceX96A > _priceX96B) {
            (_priceX96A, _priceX96B) = (_priceX96B, _priceX96A);
        }
        uint256 intermediate = _priceX96A.mulDivDown(_priceX96B, M.Q96);
        return uint128(_amount0.mulDivDown(intermediate, _priceX96B - _priceX96A));
    }

    function amount1ToLiquidityPriceX96V3(uint160 _priceX96A, uint160 _priceX96B, uint256 _amount1)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (_priceX96A > _priceX96B) {
            (_priceX96A, _priceX96B) = (_priceX96B, _priceX96A);
        }
        return uint128(_amount1.mulDivDown(M.Q96, _priceX96B - _priceX96A));
    }

    function feeGrowthV3(uint256 _feeGrowthGlobal, uint256 _feeGrowthInside, uint128 _liquidity)
        internal
        pure
        returns (uint256 fee)
    {
        uint256 feeGrowthDelta = _feeGrowthGlobal - _feeGrowthInside;
        return (uint256(_liquidity) * feeGrowthDelta) / (1 << 128);
    }

    function liquidityToAmountsTickV3(int24 _currentTick, int24 _lowTick, int24 _upperTick, uint128 _liquidity)
        internal
        pure
        returns (uint256 amount0, uint256 amount1)
    {
        // Calculate token amounts based on liquidity
        if (_currentTick < _lowTick) {
            // All token0, no token1
            amount0 = liquidityToAmount0PriceX96V3(tickToPriceX96V3(_lowTick), tickToPriceX96V3(_upperTick), _liquidity);
        } else if (_currentTick >= _upperTick) {
            // All token1, no token0
            amount1 = liquidityToAmount1PriceX96V3(tickToPriceX96V3(_lowTick), tickToPriceX96V3(_upperTick), _liquidity);
        } else {
            // Mix of token0 and token1
            amount0 =
                liquidityToAmount0PriceX96V3(tickToPriceX96V3(_currentTick), tickToPriceX96V3(_upperTick), _liquidity);
            amount1 =
                liquidityToAmount1PriceX96V3(tickToPriceX96V3(_lowTick), tickToPriceX96V3(_currentTick), _liquidity);
        }
    }

    function amountsToLiquidityTickV3(
        uint160 _priceX96,
        int24 _lowTick,
        int24 _upperTick,
        uint256 _amount0,
        uint256 _amount1
    ) internal pure returns (uint128 liquidity) {
        return amountsToLiquidityPriceX96V3(
            _priceX96, tickToPriceX96V3(_lowTick), tickToPriceX96V3(_upperTick), _amount0, _amount1
        );
    }

    function validateTickSpacing(int24 _spacing, int24 _lowTick, int24 _upperTick) internal pure returns (bool) {
        return _lowTick < _upperTick && _lowTick % _spacing == 0 && _upperTick % _spacing == 0;
    }

    function roundTickToSpacing(int24 _tick, int24 _tickSpacing, bool _roundUp) internal pure returns (int24) {
        int24 remainder = _tick % _tickSpacing;
        if (remainder == 0) return _tick;

        if (_roundUp) {
            return remainder < 0 ? _tick - remainder : _tick + (_tickSpacing - remainder);
        } else {
            return remainder < 0 ? _tick - (remainder + _tickSpacing) : _tick - remainder;
        }
    }

    function tickToQuoteV3(int24 _tick, uint128 _baseAmount, address _baseToken, address _quoteToken)
        internal
        pure
        returns (uint256 quoteAmount)
    {
        uint160 sqrtRatioX96 = tickToPriceX96V3(_tick);

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = _baseToken < _quoteToken
                ? ratioX192.mulDivDown(_baseAmount, 1 << 192)
                : uint256(1 << 192).mulDivDown(_baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = sqrtRatioX96.mulDivDown(sqrtRatioX96, 1 << 64);
            quoteAmount = _baseToken < _quoteToken
                ? ratioX128.mulDivDown(_baseAmount, 1 << 128)
                : uint256(1 << 128).mulDivDown(_baseAmount, ratioX128);
        }
    }

    function deviationState(uint160 _currentPriceX96, uint160 _meanPriceX96, uint256 _maxDeviation)
        internal
        pure
        returns (bool isStale, uint256 deviation)
    {
        if (_currentPriceX96 > _meanPriceX96) {
            deviation = (uint256(_currentPriceX96 - _meanPriceX96) * M.PREC_BPS) / uint256(_meanPriceX96);
        } else {
            deviation = (uint256(_meanPriceX96 - _currentPriceX96) * M.PREC_BPS) / uint256(_currentPriceX96);
        }
        isStale = deviation > _maxDeviation;
    }

    function priceX96RangeToTicks(uint160 _lowerPriceX96, uint160 _upperPriceX96, int24 _tickSpacing, bool _inverted)
        internal
        pure
        returns (int24 lowTick, int24 upperTick)
    {
        if (_inverted) {
            _lowerPriceX96 = invertPriceX96(_lowerPriceX96);
            _upperPriceX96 = invertPriceX96(_upperPriceX96);
        }
        unchecked {
            lowTick = roundTickToSpacing(priceX96ToTickV3(_lowerPriceX96), _tickSpacing, false);
            upperTick = roundTickToSpacing(priceX96ToTickV3(_upperPriceX96), _tickSpacing, true);
        }
    }

    function priceX96RangeToTicks(uint160 _lowerPriceX96, uint160 _upperPriceX96, int24 _tickSpacing)
        internal
        pure
        returns (int24 lowTick, int24 upperTick)
    {
        return priceX96RangeToTicks(_lowerPriceX96, _upperPriceX96, _tickSpacing, false);
    }
}
