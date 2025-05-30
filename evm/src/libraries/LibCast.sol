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
 * @title Casting Library - Type casting utilities
 * @copyright 2025
 * @notice Contains safe type casting functions and utilities
 * @dev Used for safe type conversions throughout the protocol
 * @author BTR Team
 */

library LibCast {
    error ValueOutOfCastRange();

    function toBytes32(address _addr) internal pure returns (bytes32 result) {
        assembly {
            result := _addr
        }
    }

    function toAddress(bytes32 _b) internal pure returns (address addr) {
        assembly {
            addr := and(_b, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function hashFast(address _a, address _b) internal pure returns (bytes32 c) {
        assembly {
            // load the 20-byte representations of the addresses
            let baseBytes := and(_a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let quoteBytes := and(_b, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

            // shift the first address 12 bytes (96 bits) to the left
            // then combine with the second address
            c := or(shl(96, baseBytes), quoteBytes)
        }
    }

    function toInt256(uint256 _value) internal pure returns (int256) {
        // If value > INT256_MAX, it will revert
        if (_value > uint256(type(int256).max)) revert ValueOutOfCastRange();
        return int256(_value);
    }

    function toUint256(int256 _value) internal pure returns (uint256) {
        if (_value < 0) revert ValueOutOfCastRange();
        return uint256(_value);
    }
}
