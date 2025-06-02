// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {LibBitMask} from "@libraries/LibBitMask.sol";
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
 * @title LibBitMask Test - Tests for bit manipulation functions
 * @copyright 2025
 * @notice Unit tests for bit mask operations
 * @dev Test contract for LibBitMask functionality
 * @author BTR Team
 */

contract LibBitMaskTest is Test {
    // --- SET BIT TESTS ---

    function testSetBit() public pure {
        uint256 mask = 0;

        // Set bit 0
        mask = LibBitMask.setBit(mask, 0);
        assertEq(mask, 1, "Setting bit 0 should result in 1");

        // Set bit 1
        mask = LibBitMask.setBit(mask, 1);
        assertEq(mask, 3, "Setting bit 1 should result in 3 (0b11)");

        // Set bit 7
        mask = LibBitMask.setBit(mask, 7);
        assertEq(mask, 131, "Setting bit 7 should result in 131 (0b10000011)");

        // Set already set bit (should be idempotent)
        uint256 originalMask = mask;
        mask = LibBitMask.setBit(mask, 0);
        assertEq(mask, originalMask, "Setting already set bit should not change mask");
    }

    function testSetBitHighPositions() public pure {
        uint256 mask = 0;

        // Set bit 255 (highest position)
        mask = LibBitMask.setBit(mask, 255);
        assertTrue(mask >= 2**255, "Setting bit 255 should set the highest bit");

        // Set bit 254
        mask = LibBitMask.setBit(mask, 254);
        assertTrue(mask >= 2**254, "Should handle high bit positions");
    }

    // --- GET BIT TESTS ---

    function testGetBit() public pure {
        uint256 mask = 0;

        // Test unset bits
        assertFalse(LibBitMask.getBit(mask, 0), "Bit 0 should be unset initially");
        assertFalse(LibBitMask.getBit(mask, 5), "Bit 5 should be unset initially");

        // Set some bits and test
        mask = LibBitMask.setBit(mask, 3);
        mask = LibBitMask.setBit(mask, 7);

        assertTrue(LibBitMask.getBit(mask, 3), "Bit 3 should be set");
        assertTrue(LibBitMask.getBit(mask, 7), "Bit 7 should be set");
        assertFalse(LibBitMask.getBit(mask, 0), "Bit 0 should still be unset");
        assertFalse(LibBitMask.getBit(mask, 5), "Bit 5 should still be unset");
    }

    function testGetBitHighPositions() public pure {
        uint256 mask = 0;

        mask = LibBitMask.setBit(mask, 255);
        assertTrue(LibBitMask.getBit(mask, 255), "Should be able to get bit 255");
        assertFalse(LibBitMask.getBit(mask, 254), "Bit 254 should be unset");
    }

    // --- RESET BIT TESTS ---

    function testResetBit() public pure {
        uint256 mask = 0;

        // Set multiple bits
        mask = LibBitMask.setBit(mask, 1);
        mask = LibBitMask.setBit(mask, 3);
        mask = LibBitMask.setBit(mask, 7);

        // Reset bit 3
        mask = LibBitMask.resetBit(mask, 3);
        assertFalse(LibBitMask.getBit(mask, 3), "Bit 3 should be reset");
        assertTrue(LibBitMask.getBit(mask, 1), "Bit 1 should still be set");
        assertTrue(LibBitMask.getBit(mask, 7), "Bit 7 should still be set");

        // Reset already unset bit (should be idempotent)
        uint256 originalMask = mask;
        mask = LibBitMask.resetBit(mask, 3);
        assertEq(mask, originalMask, "Resetting already unset bit should not change mask");
    }

    function testResetBitHighPositions() public pure {
        uint256 mask = 0;

        mask = LibBitMask.setBit(mask, 255);
        mask = LibBitMask.setBit(mask, 254);

        mask = LibBitMask.resetBit(mask, 255);
        assertFalse(LibBitMask.getBit(mask, 255), "Bit 255 should be reset");
        assertTrue(LibBitMask.getBit(mask, 254), "Bit 254 should still be set");
    }

    // --- RESET ALL BITS TESTS ---

    function testResetAllBits() public pure {
        uint256 mask = 0;

        // Set multiple bits
        mask = LibBitMask.setBit(mask, 0);
        mask = LibBitMask.setBit(mask, 15);
        mask = LibBitMask.setBit(mask, 255);

        // Reset all bits
        mask = LibBitMask.resetAllBits(mask);
        assertEq(mask, 0, "All bits should be reset to 0");

        // Verify all bits are unset
        assertFalse(LibBitMask.getBit(mask, 0), "Bit 0 should be unset");
        assertFalse(LibBitMask.getBit(mask, 15), "Bit 15 should be unset");
        assertFalse(LibBitMask.getBit(mask, 255), "Bit 255 should be unset");
    }

    function testResetAllBitsOnZero() public pure {
        uint256 mask = 0;
        mask = LibBitMask.resetAllBits(mask);
        assertEq(mask, 0, "Resetting all bits on zero mask should remain zero");
    }

    // --- ALL BITS SET TESTS ---

    function testAllBitsSet() public pure {
        uint256 mask = 0;

        // Empty mask should not have all bits set
        assertFalse(LibBitMask.allBitsSet(mask), "Empty mask should not have all bits set");

        // Partially filled mask should not have all bits set
        mask = LibBitMask.setBit(mask, 0);
        mask = LibBitMask.setBit(mask, 255);
        assertFalse(LibBitMask.allBitsSet(mask), "Partially filled mask should not have all bits set");

        // All bits set mask
        mask = type(uint256).max;
        assertTrue(LibBitMask.allBitsSet(mask), "All bits set mask should return true");
    }

    // --- COMPLEX OPERATIONS TESTS ---

    function testComplexBitOperations() public pure {
        uint256 mask = 0;

        // Set bits 0, 2, 4, 6, 8 (even positions)
        for (uint8 i = 0; i <= 8; i += 2) {
            mask = LibBitMask.setBit(mask, i);
        }

        // Verify pattern
        assertTrue(LibBitMask.getBit(mask, 0), "Bit 0 should be set");
        assertFalse(LibBitMask.getBit(mask, 1), "Bit 1 should be unset");
        assertTrue(LibBitMask.getBit(mask, 2), "Bit 2 should be set");
        assertFalse(LibBitMask.getBit(mask, 3), "Bit 3 should be unset");
        assertTrue(LibBitMask.getBit(mask, 4), "Bit 4 should be set");

        // Reset even bits and set odd bits
        for (uint8 i = 0; i <= 8; i++) {
            if (i % 2 == 0) {
                mask = LibBitMask.resetBit(mask, i);
            } else {
                mask = LibBitMask.setBit(mask, i);
            }
        }

        // Verify inverted pattern
        assertFalse(LibBitMask.getBit(mask, 0), "Bit 0 should now be unset");
        assertTrue(LibBitMask.getBit(mask, 1), "Bit 1 should now be set");
        assertFalse(LibBitMask.getBit(mask, 2), "Bit 2 should now be unset");
        assertTrue(LibBitMask.getBit(mask, 3), "Bit 3 should now be set");
    }

    // --- EDGE CASE TESTS ---

    function testBoundaryPositions() public pure {
        uint256 mask = 0;

        // Test position 0
        mask = LibBitMask.setBit(mask, 0);
        assertTrue(LibBitMask.getBit(mask, 0), "Position 0 should work");

        // Test position 255 (max for uint8)
        mask = LibBitMask.setBit(mask, 255);
        assertTrue(LibBitMask.getBit(mask, 255), "Position 255 should work");

        // Reset boundary positions
        mask = LibBitMask.resetBit(mask, 0);
        mask = LibBitMask.resetBit(mask, 255);
        assertFalse(LibBitMask.getBit(mask, 0), "Position 0 should be reset");
        assertFalse(LibBitMask.getBit(mask, 255), "Position 255 should be reset");
    }

    function testConsistency() public pure {
        uint256 mask = 0;

        // Set, check, reset cycle for multiple positions
        uint8[] memory positions = new uint8[](5);
        positions[0] = 1;
        positions[1] = 15;
        positions[2] = 63;
        positions[3] = 127;
        positions[4] = 200;

        // Set all positions
        for (uint256 i = 0; i < positions.length; i++) {
            mask = LibBitMask.setBit(mask, positions[i]);
        }

        // Verify all set
        for (uint256 i = 0; i < positions.length; i++) {
            assertTrue(LibBitMask.getBit(mask, positions[i]), "Position should be set");
        }

        // Reset half
        for (uint256 i = 0; i < positions.length; i += 2) {
            mask = LibBitMask.resetBit(mask, positions[i]);
        }

        // Verify pattern
        for (uint256 i = 0; i < positions.length; i++) {
            if (i % 2 == 0) {
                assertFalse(LibBitMask.getBit(mask, positions[i]), "Even index should be reset");
            } else {
                assertTrue(LibBitMask.getBit(mask, positions[i]), "Odd index should still be set");
            }
        }
    }

    // --- FUZZ TESTS ---

    function testFuzzSetGetReset(uint8 position) public pure {
        uint256 mask = 0;

        // Set bit
        mask = LibBitMask.setBit(mask, position);
        assertTrue(LibBitMask.getBit(mask, position), "Fuzz: Set bit should be gettable");

        // Reset bit
        mask = LibBitMask.resetBit(mask, position);
        assertFalse(LibBitMask.getBit(mask, position), "Fuzz: Reset bit should be unset");
    }

    function testFuzzIdempotency(uint8 position, uint256 seed) public pure {
        uint256 mask = seed;

        // Set bit twice
        uint256 mask1 = LibBitMask.setBit(mask, position);
        uint256 mask2 = LibBitMask.setBit(mask1, position);
        assertEq(mask1, mask2, "Fuzz: Setting bit twice should be idempotent");

        // Reset bit twice
        uint256 mask3 = LibBitMask.resetBit(mask2, position);
        uint256 mask4 = LibBitMask.resetBit(mask3, position);
        assertEq(mask3, mask4, "Fuzz: Resetting bit twice should be idempotent");
    }

    function testFuzzResetAll(uint256 seed) public pure {
        uint256 mask = seed;
        mask = LibBitMask.resetAllBits(mask);
        assertEq(mask, 0, "Fuzz: Reset all should always result in 0");
        assertFalse(LibBitMask.allBitsSet(mask), "Fuzz: Reset mask should not have all bits set");
    }

    function testFuzzAllBitsSet(uint256 mask) public pure {
        if (mask == type(uint256).max) {
            assertTrue(LibBitMask.allBitsSet(mask), "Fuzz: Max uint256 should have all bits set");
        } else {
            assertFalse(LibBitMask.allBitsSet(mask), "Fuzz: Non-max values should not have all bits set");
        }
    }

    // --- REAL WORLD USAGE TESTS ---

    function testRestrictionFlags() public pure {
        // Simulating how LibManagement uses bit masks for restrictions
        uint256 restrictions = 0;

        uint8 RESTRICT_SWAP_CALLER = 0;
        /* uint8 RESTRICT_SWAP_ROUTER = 1; */
        uint8 RESTRICT_BRIDGE = 2;
        uint8 APPROVE_MAX = 7;

        // Enable swap caller restriction
        restrictions = LibBitMask.setBit(restrictions, RESTRICT_SWAP_CALLER);
        assertTrue(LibBitMask.getBit(restrictions, RESTRICT_SWAP_CALLER), "Swap caller restriction should be enabled");

        // Enable approve max
        restrictions = LibBitMask.setBit(restrictions, APPROVE_MAX);
        assertTrue(LibBitMask.getBit(restrictions, APPROVE_MAX), "Approve max should be enabled");
        assertFalse(LibBitMask.getBit(restrictions, RESTRICT_BRIDGE), "Bridge restriction should still be disabled");

        // Disable swap caller restriction
        restrictions = LibBitMask.resetBit(restrictions, RESTRICT_SWAP_CALLER);
        assertFalse(LibBitMask.getBit(restrictions, RESTRICT_SWAP_CALLER), "Swap caller restriction should be disabled");
        assertTrue(LibBitMask.getBit(restrictions, APPROVE_MAX), "Approve max should still be enabled");
    }

    function testPermissionBitPattern() public pure {
        uint256 permissions = 0;

        // Set read permissions (bits 0-2)
        permissions = LibBitMask.setBit(permissions, 0); // READ_USER
        permissions = LibBitMask.setBit(permissions, 1); // READ_ADMIN
        permissions = LibBitMask.setBit(permissions, 2); // READ_SYSTEM

        // Set write permissions (bits 3-5)
        permissions = LibBitMask.setBit(permissions, 3); // WRITE_USER
        permissions = LibBitMask.setBit(permissions, 4); // WRITE_ADMIN

        // Verify pattern
        assertTrue(LibBitMask.getBit(permissions, 0), "READ_USER should be set");
        assertTrue(LibBitMask.getBit(permissions, 1), "READ_ADMIN should be set");
        assertTrue(LibBitMask.getBit(permissions, 2), "READ_SYSTEM should be set");
        assertTrue(LibBitMask.getBit(permissions, 3), "WRITE_USER should be set");
        assertTrue(LibBitMask.getBit(permissions, 4), "WRITE_ADMIN should be set");
        assertFalse(LibBitMask.getBit(permissions, 5), "WRITE_SYSTEM should be unset");

        // Remove all write permissions
        permissions = LibBitMask.resetBit(permissions, 3);
        permissions = LibBitMask.resetBit(permissions, 4);

        // Verify read permissions remain
        assertTrue(LibBitMask.getBit(permissions, 0), "READ_USER should still be set");
        assertTrue(LibBitMask.getBit(permissions, 1), "READ_ADMIN should still be set");
        assertFalse(LibBitMask.getBit(permissions, 3), "WRITE_USER should be unset");
        assertFalse(LibBitMask.getBit(permissions, 4), "WRITE_ADMIN should be unset");
    }
}
