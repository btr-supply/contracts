// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

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
    // === ADDRESS <-> BYTES32 CONVERSIONS ===

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

    // === SIGNED <-> UNSIGNED CONVERSIONS ===

    function toInt256(uint256 _value) internal pure returns (int256) {
        require(_value <= uint256(type(int256).max)); // out of cast range
        return int256(_value);
    }

    function toUint256(int256 _value) internal pure returns (uint256) {
        require(_value >= 0); // out of cast range
        return uint256(_value);
    }

    function toInt128(uint128 _value) internal pure returns (int128) {
        require(_value <= uint128(type(int128).max)); // out of cast range
        return int128(_value);
    }

    function toUint128(int128 _value) internal pure returns (uint128) {
        require(_value >= 0); // out of cast range
        return uint128(_value);
    }

    // === UINT DOWNCASTING CONVERSIONS ===

    function toUint128(uint256 _value) internal pure returns (uint128) {
        require(_value <= type(uint128).max); // out of cast range
        return uint128(_value);
    }

    function toUint64(uint256 _value) internal pure returns (uint64) {
        require(_value <= type(uint64).max); // out of cast range
        return uint64(_value);
    }

    function toUint32(uint256 _value) internal pure returns (uint32) {
        require(_value <= type(uint32).max); // out of cast range
        return uint32(_value);
    }

    function toUint16(uint256 _value) internal pure returns (uint16) {
        require(_value <= type(uint16).max); // out of cast range
        return uint16(_value);
    }

    function toUint8(uint256 _value) internal pure returns (uint8) {
        require(_value <= type(uint8).max); // out of cast range
        return uint8(_value);
    }

    // === BYTES CONVERSIONS ===

    function toBytes4(bytes32 _value) internal pure returns (bytes4) {
        return bytes4(_value);
    }

    function toBytes32(bytes4 _value) internal pure returns (bytes32) {
        return bytes32(_value);
    }

    function toBytes8(bytes32 _value) internal pure returns (bytes8) {
        return bytes8(_value);
    }

    function toBytes32(bytes8 _value) internal pure returns (bytes32) {
        return bytes32(_value);
    }

    function toBytes16(bytes32 _value) internal pure returns (bytes16) {
        return bytes16(_value);
    }

    function toBytes32(bytes16 _value) internal pure returns (bytes32) {
        return bytes32(_value);
    }

    // === BOOLEAN CONVERSIONS ===

    function toBool(uint256 _value) internal pure returns (bool) {
        return _value != 0;
    }

    function toUint256(bool _value) internal pure returns (uint256) {
        return _value ? 1 : 0;
    }

    function toUint8(bool _value) internal pure returns (uint8) {
        return _value ? 1 : 0;
    }

    // === STRING <-> BYTES32 CONVERSIONS ===

    function toBytes32(string memory _str) internal pure returns (bytes32 result) {
        bytes memory strBytes = bytes(_str);
        require(strBytes.length <= 32); // string too long

        assembly {
            result := mload(add(strBytes, 32))
        }
    }

    function toString(bytes32 _bytes) internal pure returns (string memory) {
        uint256 length = 0;

        // Find the length of the string (until null terminator)
        for (uint256 i = 0; i < 32; i++) {
            if (_bytes[i] == 0) break;
            length++;
        }

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = _bytes[i];
        }

        return string(result);
    }

    // === HASH UTILITIES ===

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

    function hashFast(uint256 _a, uint256 _b) internal pure returns (bytes32 c) {
        assembly {
            // Store values in memory and hash
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            c := keccak256(ptr, 0x40)
        }
    }

    function hashFast(bytes32 _a, bytes32 _b) internal pure returns (bytes32 c) {
        assembly {
            // Store values in memory and hash
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            c := keccak256(ptr, 0x40)
        }
    }

    // === UTILITY FUNCTIONS ===

    function packUint128(uint128 _a, uint128 _b) internal pure returns (uint256 packed) {
        assembly {
            packed := or(shl(128, _a), _b)
        }
    }

    function unpackUint128(uint256 _packed) internal pure returns (uint128 a, uint128 b) {
        assembly {
            a := shr(128, _packed)
            b := and(_packed, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function packAddress(address _a, address _b) internal pure returns (uint256 packed) {
        assembly {
            packed := or(shl(160, _a), _b)
        }
    }

    function unpackAddress(uint256 _packed) internal pure returns (address a, address b) {
        assembly {
            a := shr(160, _packed)
            b := and(_packed, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
}
