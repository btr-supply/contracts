// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Bit Mask Library - Bit manipulation utilities
 * @copyright 2025
 * @notice Contains functions for working with bitmasks
 * @dev Useful for managing flags or compact storage
 * @author BTR Team
 */

library LibBitMask {
    uint256 private constant BITS = type(uint256).max;

    function setBit(uint256 _bitmask, uint8 _position) internal pure returns (uint256) {
        return _bitmask | (1 << _position);
    }

    function getBit(uint256 _bitmask, uint8 _position) internal pure returns (bool) {
        return (_bitmask & (1 << _position)) != 0;
    }

    function resetBit(uint256 _bitmask, uint8 _position) internal pure returns (uint256) {
        return _bitmask & ~(1 << _position);
    }

    function resetAllBits(uint256 /* _bitmask */ ) internal pure returns (uint256) {
        return 0;
    }

    function allBitsSet(uint256 _bitmask) internal pure returns (bool) {
        return _bitmask == BITS;
    }
}
