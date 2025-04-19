// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title LibDEXMaths
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in sqrtPriceMath.sol
library LibDEXMaths {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}
