// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/*
 * @title Convert Library - Data conversion utilities
 * @copyright 2025
 * @notice Contains internal functions for data type conversions
 * @dev Minimal library for UniV4Adapter compatibility
 * @author BTR Team
 */
library LibConvert {
    /// @notice Convert bytes32 to address
    function toAddress(bytes32 _value) internal pure returns (address) {
        return address(uint160(uint256(_value)));
    }

    /// @notice Convert address to bytes32
    function toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /// @notice Convert uint256 to uint128 with overflow check
    function toUint128(uint256 _value) internal pure returns (uint128) {
        require(_value <= type(uint128).max, "LibConvert: uint128 overflow");
        return uint128(_value);
    }

    /// @notice Convert uint256 to uint96 with overflow check
    function toUint96(uint256 _value) internal pure returns (uint96) {
        require(_value <= type(uint96).max, "LibConvert: uint96 overflow");
        return uint96(_value);
    }
}
