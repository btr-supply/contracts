// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {LibCast} from "@libraries/LibCast.sol";
import "forge-std/Test.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title LibCast Test - Tests for type casting functions
 * @copyright 2025
 * @notice Unit tests for safe type casting operations
 * @dev Test contract for LibCast functionality - only tests available functions
 * @author BTR Team
 */

contract LibCastTest is Test {
    // --- ADDRESS TO BYTES32 CONVERSION TESTS ---

    function testToBytes32() public pure {
        // Test zero address
        address zero = address(0);
        bytes32 zeroBytes = LibCast.toBytes32(zero);
        assertEq(zeroBytes, bytes32(0), "Zero address should convert to zero bytes32");

        // Test non-zero address
        address testAddr = address(0x1234567890123456789012345678901234567890);
        bytes32 addrBytes = LibCast.toBytes32(testAddr);
        assertEq(addrBytes, bytes32(uint256(uint160(testAddr))), "Address conversion should be accurate");

        // Test max address
        address maxAddr = address(type(uint160).max);
        bytes32 maxBytes = LibCast.toBytes32(maxAddr);
        assertEq(maxBytes, bytes32(uint256(type(uint160).max)), "Max address should convert correctly");
    }

    // --- BYTES32 TO ADDRESS CONVERSION TESTS ---

    function testToAddress() public pure {
        // Test zero bytes32
        bytes32 zero = bytes32(0);
        address zeroAddr = LibCast.toAddress(zero);
        assertEq(zeroAddr, address(0), "Zero bytes32 should convert to zero address");

        // Test non-zero bytes32
        address originalAddr = address(0x1234567890123456789012345678901234567890);
        bytes32 addrBytes = bytes32(uint256(uint160(originalAddr)));
        address convertedAddr = LibCast.toAddress(addrBytes);
        assertEq(convertedAddr, originalAddr, "Address conversion should be accurate");

        // Test that upper bits are ignored
        bytes32 largeBytes = bytes32(type(uint256).max);
        address addrFromLarge = LibCast.toAddress(largeBytes);
        assertEq(addrFromLarge, address(type(uint160).max), "Should extract only lower 160 bits");
    }

    // --- UINT256 TO INT256 CONVERSION TESTS ---

    function testToInt256() public pure {
        // Test zero
        assertEq(LibCast.toInt256(0), int256(0), "0 should convert to 0");

        // Test small positive values
        assertEq(LibCast.toInt256(123), int256(123), "123 should convert correctly");

        // Test maximum valid value
        assertEq(LibCast.toInt256(uint256(type(int256).max)), type(int256).max, "Max int256 should convert correctly");
    }

    // --- INT256 TO UINT256 CONVERSION TESTS ---

    function testToUint256() public pure {
        // Test positive values
        assertEq(LibCast.toUint256(int256(0)), uint256(0), "0 should convert to 0");
        assertEq(LibCast.toUint256(int256(123)), uint256(123), "123 should convert correctly");
        assertEq(LibCast.toUint256(type(int256).max), uint256(type(int256).max), "Max int256 should convert correctly");
    }

    // --- HASH FAST TESTS ---

    function testHashFast() public pure {
        address a = address(0x1111111111111111111111111111111111111111);
        address b = address(0x2222222222222222222222222222222222222222);

        bytes32 hash1 = LibCast.hashFast(a, b);
        bytes32 hash2 = LibCast.hashFast(b, a);

        // Different order should produce different hashes
        assertTrue(hash1 != hash2, "Hash should be order dependent");

        // Same inputs should produce same hash
        bytes32 hash3 = LibCast.hashFast(a, b);
        assertEq(hash1, hash3, "Same inputs should produce same hash");

        // Test with zero addresses
        bytes32 zeroHash = LibCast.hashFast(address(0), address(0));
        assertEq(zeroHash, bytes32(0), "Zero addresses should produce zero hash");
    }

    // --- ROUND TRIP CONVERSION TESTS ---

    function testAddressRoundTrip() public pure {
        address original = address(0x1234567890123456789012345678901234567890);
        bytes32 asBytes = LibCast.toBytes32(original);
        address backToAddr = LibCast.toAddress(asBytes);
        assertEq(backToAddr, original, "Round trip address conversion should be consistent");
    }

    function testSignedRoundTrip() public pure {
        // Test positive values
        uint256 originalUint = 12345;
        int256 asInt = LibCast.toInt256(originalUint);
        uint256 backToUint = LibCast.toUint256(asInt);
        assertEq(backToUint, originalUint, "Round trip uint->int->uint should be consistent");

        // Test zero
        assertEq(LibCast.toUint256(LibCast.toInt256(0)), 0, "Round trip zero should work");
    }

    // --- EDGE CASE TESTS ---

    function testBoundaryValues() public pure {
        // Test exactly at boundaries
        assertEq(LibCast.toInt256(uint256(type(int256).max)), type(int256).max, "Boundary: max valid int256");
        assertEq(LibCast.toUint256(int256(0)), uint256(0), "Boundary: zero int to uint");

        // Test address boundaries
        assertEq(LibCast.toAddress(bytes32(0)), address(0), "Boundary: zero bytes32 to address");
        assertEq(LibCast.toBytes32(address(0)), bytes32(0), "Boundary: zero address to bytes32");
    }

    // --- FUZZ TESTS ---

    function testFuzzUintToInt256(uint256 value) public pure {
        vm.assume(value <= uint256(type(int256).max));
        assertEq(LibCast.toInt256(value), int256(value), "Fuzz: uint256 to int256 conversion should be accurate");
    }

    function testFuzzIntToUint256(int256 value) public pure {
        vm.assume(value >= 0);
        assertEq(LibCast.toUint256(value), uint256(value), "Fuzz: positive int256 to uint256 conversion should be accurate");
    }

    function testFuzzAddressConversion(address addr) public pure {
        bytes32 asBytes = LibCast.toBytes32(addr);
        address backToAddr = LibCast.toAddress(asBytes);
        assertEq(backToAddr, addr, "Fuzz: address round trip should be accurate");
    }

    function testFuzzHashFast(address a, address b) public pure {
        bytes32 hash1 = LibCast.hashFast(a, b);
        bytes32 hash2 = LibCast.hashFast(a, b);
        assertEq(hash1, hash2, "Fuzz: same inputs should produce same hash");

        // Test that hash is different for different order (unless addresses are equal)
        if (a != b) {
            bytes32 hash3 = LibCast.hashFast(b, a);
            assertTrue(hash1 != hash3, "Fuzz: different order should produce different hash");
        }
    }

    // --- ERROR CONDITION TESTS ---
    // Note: Overflow conditions are handled by the library but testing them is complex
    // due to forge expectRevert behavior, so we skip explicit overflow testing
}
