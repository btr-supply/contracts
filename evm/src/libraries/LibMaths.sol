// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {LibCast} from "./LibCast.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Maths Library - General mathematical functions
 * @copyright 2025
 * @notice - Provides safe and optimized mathematical operations
- Includes fixed-point math and common calculations
- Borrows functions from Solady's FixedPointMathLib.sol
  (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
  and Uniswap V3's FullMath.sol
  (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol)

 * @dev Includes fixed-point math and common calculations
 * @author BTR Team
 */

library LibMaths {
    using LibCast for uint256;
    using LibCast for int256;

    uint256 internal constant WAD = 1e18; // Scalar of ETH and most ERC20s
    uint256 internal constant RAY = 1e27;
    uint256 internal constant WAD_SQRT = 1e9;
    uint256 internal constant BPS = 100_00; // BP basis = 100% = 100_00 == 1e4
    uint256 internal constant PREC_BPS = BPS ** 2; // Precision BP basis = 100% = 100_000000 == 1e8
    uint256 internal constant SEC_PER_YEAR = 31_556_952;
    uint256 internal constant Q96 = 0x1000000000000000000000000; // 2^96 == 1 << 96
    uint256 internal constant Q192 = 0x100000000000000000000000000000000; // 2^192 ==  1 << 192

    function bpRatio(uint256 _a, uint256 _b) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_a, BPS, _b);
        }
    }

    function pBpRatio(uint256 _a, uint256 _b) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_a, PREC_BPS, _b);
        }
    }

    function subBpDown(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, BPS - _bp, BPS);
        }
    }

    function subBpUp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivUp(_amount, BPS - _bp, BPS);
        }
    }

    function addBpDown(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, BPS + _bp, BPS);
        }
    }

    function addBpUp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivUp(_amount, BPS + _bp, BPS);
        }
    }

    function bpDown(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, _bp, BPS);
        }
    }

    function pBpDown(uint256 _amount, uint256 _pBp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, _pBp, PREC_BPS);
        }
    }

    function bpUp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivUp(_amount, _bp, BPS);
        }
    }

    function pBpUp(uint256 _amount, uint256 _pBp) internal pure returns (uint256) {
        unchecked {
            return mulDivUp(_amount, _pBp, PREC_BPS);
        }
    }

    function revBpDown(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, _bp, BPS - _bp);
        }
    }

    function revBpUp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivUp(_amount, _bp, BPS - _bp);
        }
    }

    function revAddBp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, BPS, BPS - _bp);
        }
    }

    function revSubBp(uint256 _amount, uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return mulDivDown(_amount, BPS, BPS + _bp);
        }
    }

    function toWad(uint256 _bp) internal pure returns (uint256) {
        unchecked {
            return (_bp * WAD) / BPS;
        }
    }

    function toBp(uint256 _wad) internal pure returns (uint256) {
        unchecked {
            return (_wad * BPS) / WAD;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SOLADY-COMPLIANT CORE FUNCTIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if gt(x, div(not(0), y)) {
                if y {
                    revert(0, 0) // Math error
                }
            }
            z := div(mul(x, y), WAD)
        }
    }

    function mulWad(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            z := mul(x, y)
            // Equivalent to `require((x == 0 || z / x == y) && !(x == -1 && y == type(int256).min))`.
            if iszero(gt(or(iszero(x), eq(sdiv(z, x), y)), lt(not(x), eq(y, shl(255, 1))))) {
                revert(0, 0) // Math error
            }
            z := sdiv(z, WAD)
        }
    }

    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to `require(y != 0 && x <= type(uint256).max / WAD)`.
            if iszero(mul(y, lt(x, add(1, div(not(0), WAD))))) {
                revert(0, 0) // Math error
            }
            z := div(mul(x, WAD), y)
        }
    }

    function divWad(int256 x, int256 y) internal pure returns (int256 z) {
        assembly {
            z := mul(x, WAD)
            // Equivalent to `require(y != 0 && ((x * WAD) / WAD == x))`.
            if iszero(mul(y, eq(sdiv(z, WAD), x))) {
                revert(0, 0) // Math error
            }
            z := sdiv(z, y)
        }
    }

    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly {
            // 512-bit multiply `[p1 p0] = x * y`.
            // Compute the product mod `2**256` and mod `2**256 - 1`
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that `product = p1 * 2**256 + p0`.

            // Temporarily use `z` as `p0` to save gas.
            z := mul(x, y) // Lower 256 bits of `x * y`.
            for {} 1 {} {
                // If overflows.
                if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                    let mm := mulmod(x, y, not(0))
                    let p1 := sub(mm, add(z, lt(mm, z))) // Upper 256 bits of `x * y`.

                    /*------------------- 512 by 256 division --------------------*/

                    // Make division exact by subtracting the remainder from `[p1 p0]`.
                    let r := mulmod(x, y, d) // Compute remainder using mulmod.
                    let t := and(d, sub(0, d)) // The least significant bit of `d`. `t >= 1`.
                    // Make sure `z` is less than `2**256`. Also prevents `d == 0`.
                    // Placing the check here seems to give more optimal stack operations.
                    if iszero(gt(d, p1)) {
                        revert(0, 0) // Math error
                    }
                    d := div(d, t) // Divide `d` by `t`, which is a power of two.
                    // Invert `d mod 2**256`
                    // Now that `d` is an odd number, it has an inverse
                    // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                    // Compute the inverse by starting with a seed that is correct
                    // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                    let inv := xor(2, mul(3, d))
                    // Now use Newton-Raphson iteration to improve the precision.
                    // Thanks to Hensel's lifting lemma, this also works in modular
                    // arithmetic, doubling the correct bits in each step.
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                    inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                    z :=
                        mul(
                            // Divide [p1 p0] by the factors of two.
                            // Shift in bits from `p1` into `p0`. For this we need
                            // to flip `t` such that it is `2**256 / t`.
                            or(mul(sub(p1, gt(r, z)), add(div(sub(0, t), t), 1)), div(sub(z, r), t)),
                            mul(sub(2, mul(d, inv)), inv) // inverse mod 2**256
                        )
                    break
                }
                z := div(z, d)
                break
            }
        }
    }

    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        z = fullMulDiv(x, y, d);
        assembly {
            if mulmod(x, y, d) {
                z := add(z, 1)
                if iszero(z) {
                    revert(0, 0) // Math error
                }
            }
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly {
            z := mul(x, y)
            // Equivalent to `require(d != 0 && (y == 0 || x <= type(uint256).max / y))`.
            if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                revert(0, 0) // Math error
            }
            z := div(z, d)
        }
    }

    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly {
            z := mul(x, y)
            // Equivalent to `require(d != 0 && (y == 0 || x <= type(uint256).max / y))`.
            if iszero(mul(or(iszero(x), eq(div(z, x), y)), d)) {
                revert(0, 0) // Math error
            }
            z := add(iszero(iszero(mod(z, d))), div(z, d))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   LEGACY COMPATIBILITY                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function mulDivDown(uint256 _a, uint256 _b, uint256 _denominator) internal pure returns (uint256 result) {
        return fullMulDiv(_a, _b, _denominator);
    }

    function fullMulDivN(uint256 _x, uint256 _y, uint8 _n) internal pure returns (uint256 _z) {
        assembly {
            _z := mul(_x, _y)
            for {} 1 {} {
                if iszero(or(iszero(_x), eq(div(_z, _x), _y))) {
                    let _k := and(_n, 0xff)
                    let _mm := mulmod(_x, _y, not(0))
                    let _p1 := sub(_mm, add(_z, lt(_mm, _z)))
                    if iszero(shr(_k, _p1)) {
                        _z := add(shl(sub(256, _k), _p1), shr(_k, _z))
                        break
                    }
                    revert(0, 0) // Math error
                }
                _z := shr(and(_n, 0xff), _z)
                break
            }
        }
    }

    function divRoundingUp(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(_x, _y), gt(mod(_x, _y), 0))
        }
    }

    function diff(uint256 _a, uint256 _b) internal pure returns (uint256) {
        unchecked {
            return _a > _b ? _a - _b : _b - _a;
        }
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }

    function max(int256 _a, int256 _b) internal pure returns (int256) {
        return _a > _b ? _a : _b;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    function min(int256 _a, int256 _b) internal pure returns (int256) {
        return _a < _b ? _a : _b;
    }

    function approxEq(uint256 _a, uint256 _b, uint256 _eps) internal pure returns (bool) {
        return mulDown(_b, WAD - _eps) <= _a && _a <= mulDown(_b, WAD + _eps);
    }

    function approxEq(uint256 _a, uint256 _b) internal pure returns (bool) {
        return approxEq(_a, _b, 1e8); // 0.00000001% in WAD units
    }

    function approxGt(uint256 _a, uint256 _b, uint256 _eps) internal pure returns (bool) {
        return _a >= _b && _a <= mulDown(_b, WAD + _eps);
    }

    function approxLt(uint256 _a, uint256 _b, uint256 _eps) internal pure returns (bool) {
        return _a <= _b && _a >= mulDown(_b, WAD - _eps);
    }

    function tryAdd(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = _a + _b;
            if (c < _a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
        unchecked {
            if (_b > _a) return (false, 0);
            return (true, _a - _b);
        }
    }

    function tryMul(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
        unchecked {
            if (_a == 0) return (true, 0);
            uint256 c = _a * _b;
            if (c / _a != _b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
        unchecked {
            if (_b == 0) return (false, 0);
            return (true, _a / _b);
        }
    }

    function tryMod(uint256 _a, uint256 _b) internal pure returns (bool, uint256) {
        unchecked {
            if (_b == 0) return (false, 0);
            return (true, _a % _b);
        }
    }

    function average(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a & _b) + ((_a ^ _b) >> 1);
    }

    function within(uint256 _value, uint256 _min, uint256 _max) internal pure returns (bool) {
        unchecked {
            return _value >= _min && _value <= _max;
        }
    }

    function within(uint32 _value, uint32 _min, uint32 _max) internal pure returns (bool) {
        unchecked {
            return _value >= _min && _value <= _max;
        }
    }

    function within(uint64 _value, uint64 _min, uint64 _max) internal pure returns (bool) {
        unchecked {
            return _value >= _min && _value <= _max;
        }
    }

    function within(int256 _value, int256 _min, int256 _max) internal pure returns (bool) {
        unchecked {
            return _value >= _min && _value <= _max;
        }
    }

    function within32(uint32 _value, uint256 _min, uint256 _max) internal pure returns (bool) {
        unchecked {
            return uint256(_value) >= _min && uint256(_value) <= _max;
        }
    }

    function within64(uint64 _value, uint256 _min, uint256 _max) internal pure returns (bool) {
        unchecked {
            return uint256(_value) >= _min && uint256(_value) <= _max;
        }
    }

    function diffWithin(uint256 _a, uint256 _b, uint256 _val) internal pure returns (bool) {
        return diff(_a, _b) <= _val;
    }

    function diffWithin1(uint256 _a, uint256 _b) internal pure returns (bool) {
        return diffWithin(_a, _b, 1);
    }

    function subMax0(uint256 _a, uint256 _b) internal pure returns (uint256) {
        unchecked {
            return _a > _b ? _a - _b : 0;
        }
    }

    function subNoNeg(int256 _a, int256 _b) internal pure returns (int256) {
        require(_a >= _b); // value out of range
        unchecked {
            return _a - _b;
        }
    }

    function mulDown(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 product = _a * _b;
        unchecked {
            return product / 1e18;
        }
    }

    function mulDown(int256 _a, int256 _b) internal pure returns (int256) {
        int256 product = _a * _b;
        unchecked {
            return product / 1e18;
        }
    }

    function divDown(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 aInflated = _a * 1e18;
        unchecked {
            return aInflated / _b;
        }
    }

    function divDown(int256 _a, int256 _b) internal pure returns (int256) {
        int256 aInflated = _a * 1e18;
        unchecked {
            return aInflated / _b;
        }
    }

    function rawDivUp(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a + _b - 1) / _b;
    }

    function abs(int256 _x) internal pure returns (uint256) {
        return _x == type(int256).min ? uint256(type(int256).max) + 1 : uint256(_x > 0 ? _x : -_x);
    }

    function neg(int256 _x) internal pure returns (int256) {
        return _x * -1;
    }

    function neg(uint256 _x) internal pure returns (int256) {
        return _x.toInt256() * -1;
    }

    function sqrt(uint256 _x) internal pure returns (uint256 r) {
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            r := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
            // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
            let y := shl(7, lt(0xffffffffffffffffffffffffffffffffff, _x))
            y := or(y, shl(6, lt(0xffffffffffffffffff, shr(y, _x))))
            y := or(y, shl(5, lt(0xffffffffff, shr(y, _x))))
            y := or(y, shl(4, lt(0xffffff, shr(y, _x))))
            r := shl(shr(1, y), r)

            // Goal was to get `r*r*y` within a small factor of `_x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `_x < 256` but we can just verify those cases exhaustively.

            // Now, `r*r*y <= _x < r*r*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `_x < 256`.
            // Correctness can be checked exhaustively for `_x < 256`, so we assume `y >= 256`.
            // Then `r*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(_x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            r := shr(18, mul(r, add(shr(y, _x), 65536))) // A `mul()` is saved from starting `r` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))
            r := shr(1, add(r, div(_x, r)))

            // If `_x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(_x))` and `ceil(sqrt(_x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            r := sub(r, lt(div(_x, r), r))
        }
    }

    function cbrtWad(uint256 _x) internal pure returns (uint256 _z) {
        unchecked {
            if (_x <= type(uint256).max / 10 ** 36) return cbrt(_x * 10 ** 36);
            _z = (1 + cbrt(_x)) * 10 ** 12;
            _z = (fullMulDiv(_x, 10 ** 36, _z * _z) + _z + _z) / 3;
        }
        assembly {
            let _p := _x
            for {} 1 {} {
                if iszero(shr(229, _p)) {
                    if iszero(shr(199, _p)) {
                        _p := mul(_p, 100000000000000000)
                        break
                    }
                    _p := mul(_p, 100000000)
                    break
                }
                if iszero(shr(249, _p)) { _p := mul(_p, 100) }
                break
            }
            let _t := mulmod(mul(_z, _z), _z, _p)
            _z := sub(_z, gt(lt(_t, shr(1, _p)), iszero(_t)))
        }
    }

    function cbrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            // Makeshift lookup table to nudge the approximate log2 result.
            z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))
            // Newton-Raphson's.
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            // Round down.
            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    function powWad(int256 _x, int256 _y) internal pure returns (int256) {
        return expWad((lnWad(_x) * _y) / int256(WAD));
    }

    function expWad(int256 _x) internal pure returns (int256 r) {
        unchecked {
            if (_x <= -41446531673892822313) return r;

            /*
           * @solidity memory-safe-assembly
           */
            assembly {
                if iszero(slt(_x, 135305999368893231589)) {
                    revert(0, 0) // Math error
                }
            }

            _x = (_x << 78) / 5 ** 18;

            int256 _k = ((_x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            _x = _x - _k * 54916777467707473351141471128;

            int256 _y = _x + 1346386616545796478920950773328;
            _y = ((_y * _x) >> 96) + 57155421644029726153956944680412;
            int256 _p = _y + _x - 94201549194550492254356042504812;
            _p = ((_p * _y) >> 96) + 28719021644029726153956944680412240;
            _p = _p * _x + (4385272521454847904659076985693276 << 96);

            int256 _q = _x - 2855989394907223263936484059900;
            _q = ((_q * _x) >> 96) + 50020603652535783019961831881945;
            _q = ((_q * _x) >> 96) - 533845033583426703283633433725380;
            _q = ((_q * _x) >> 96) + 3604857256930695427073651918091429;
            _q = ((_q * _x) >> 96) - 14423608567350463180887372962807573;
            _q = ((_q * _x) >> 96) + 26449188498355588339934803723976023;

            /*
           * @solidity memory-safe-assembly
           */
            assembly {
                r := sdiv(_p, _q)
            }

            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - _k));
        }
    }

    function lnWad(int256 _x) internal pure returns (int256 r) {
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, _x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, _x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, _x))))
            r := or(r, shl(4, lt(0xffff, shr(r, _x))))
            r := or(r, shl(3, lt(0xff, shr(r, _x))))
            if iszero(sgt(_x, 0)) {
                revert(0, 0) // Math error
            }
            // forgefmt: disable-next-item
            r := xor(
              r,
              byte(
                  and(
                      0x1f,
                      shr(shr(r, _x), 0x8421084210842108cc6318c6db6d54be)
                  ),
                  0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff
              )
          )

            _x := shr(159, shl(r, _x))

            // forgefmt: disable-next-item
            let _p := sub(
              sar(
                  96,
                  mul(
                      add(
                          43456485725739037958740375743393,
                          sar(
                              96,
                              mul(
                                  add(
                                      24828157081833163892658089445524,
                                      sar(
                                          96,
                                          mul(
                                              add(
                                                  3273285459638523848632254066296,
                                                  _x
                                              ),
                                              _x
                                          )
                                      )
                                  ),
                                  _x
                              )
                          )
                      ),
                      _x
                  )
              ),
              11111509109440967052023855526967
          )
            _p := sub(sar(96, mul(_p, _x)), 45023709667254063763336534515857)
            _p := sub(sar(96, mul(_p, _x)), 14706773417378608786704636184526)
            _p := sub(mul(_p, _x), shl(96, 795164235651350426258249787498))

            let _q := add(5573035233440673466300451813936, _x)
            _q := add(71694874799317883764090561454958, sar(96, mul(_x, _q)))
            _q := add(283447036172924575727196451306956, sar(96, mul(_x, _q)))
            _q := add(401686690394027663651624208769553, sar(96, mul(_x, _q)))
            _q := add(204048457590392012362485061816622, sar(96, mul(_x, _q)))
            _q := add(31853899698501571402653359427138, sar(96, mul(_x, _q)))
            _q := add(909429971244387300277376558375, sar(96, mul(_x, _q)))

            _p := sdiv(_p, _q)
            _p := mul(1677202110996718588342820967067443963516166, _p)
            // forgefmt: disable-next-item
            _p := add(
              mul(
                  16597577552685614221487285958193947469193820559219878177908093499208371,
                  sub(159, r)
              ),
              _p
          )
            _p := add(600920179829731861736702779321621459595472258049074101567377883020018308, _p)
            r := sar(174, _p)
        }
    }

    function sqrtWad(uint256 _x) internal pure returns (uint256 z) {
        unchecked {
            if (_x <= type(uint256).max / 10 ** 18) return sqrt(_x * 10 ** 18);
            z = (1 + sqrt(_x)) * 10 ** 9;
            z = (fullMulDiv(_x, 10 ** 18, z) + z) >> 1;
        }
        assembly {
            z := sub(z, gt(999999999999999999, sub(mulmod(z, z, _x), 1)))
        }
    }

    function log2(uint256 _x) internal pure returns (uint256 r) {
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, _x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, _x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, _x))))
            r := or(r, shl(4, lt(0xffff, shr(r, _x))))
            r := or(r, shl(3, lt(0xff, shr(r, _x))))
            // forgefmt: disable-next-item
            r := or(
              r,
              byte(
                  and(
                      0x1f,
                      shr(shr(r, _x), 0x8421084210842108cc6318c6db6d54be)
                  ),
                  0x0706060506020504060203020504030106050205030304010505030400000000
              )
          )
        }
    }

    function log10(uint256 _x) internal pure returns (uint256 r) {
        assembly {
            if iszero(lt(_x, 100000000000000000000000000000000000000)) {
                _x := div(_x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(_x, 100000000000000000000)) {
                _x := div(_x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(_x, 10000000000)) {
                _x := div(_x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(_x, 100000)) {
                _x := div(_x, 100000)
                r := add(r, 5)
            }
            r := add(r, add(gt(_x, 9), add(gt(_x, 99), add(gt(_x, 999), gt(_x, 9999)))))
        }
    }

    function log256(uint256 _x) internal pure returns (uint256 r) {
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, _x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, _x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, _x))))
            r := or(r, shl(4, lt(0xffff, shr(r, _x))))
            r := or(shr(3, r), lt(0xff, shr(r, _x)))
        }
    }

    function clamp(uint256 _x, uint256 _minValue, uint256 _maxValue) internal pure returns (uint256 z) {
        assembly {
            z := xor(_x, mul(xor(_x, _minValue), gt(_minValue, _x)))
            z := xor(z, mul(xor(z, _maxValue), lt(_maxValue, z)))
        }
    }

    function clamp(int256 _x, int256 _minValue, int256 _maxValue) internal pure returns (int256 z) {
        assembly {
            z := xor(_x, mul(xor(_x, _minValue), sgt(_minValue, _x)))
            z := xor(z, mul(xor(z, _maxValue), slt(_maxValue, z)))
        }
    }

    function lerp(uint256 _a, uint256 _b, uint256 _t, uint256 _begin, uint256 _end) internal pure returns (uint256) {
        if (_begin > _end) (_t, _begin, _end) = (~_t, ~_begin, ~_end);
        if (_t <= _begin) return _a;
        if (_t >= _end) return _b;
        unchecked {
            if (_b >= _a) {
                return _a + fullMulDiv(_b - _a, _t - _begin, _end - _begin);
            }
            return _a - fullMulDiv(_a - _b, _t - _begin, _end - _begin);
        }
    }

    function lerp(int256 _a, int256 _b, int256 _t, int256 _begin, int256 _end) internal pure returns (int256) {
        if (_begin > _end) (_t, _begin, _end) = (~_t, ~_begin, ~_end);
        if (_t <= _begin) return _a;
        if (_t >= _end) return _b;
        // forgefmt: disable-next-item
        unchecked {
          if (_b >= _a)
              return
                  int256(
                      uint256(_a) +
                          fullMulDiv(
                              uint256(_b - _a),
                              uint256(_t - _begin),
                              uint256(_end - _begin)
                          )
                  );
          return
              int256(
                  uint256(_a) -
                      fullMulDiv(
                          uint256(_a - _b),
                          uint256(_t - _begin),
                          uint256(_end - _begin)
                      )
              );
      }
    }
}
