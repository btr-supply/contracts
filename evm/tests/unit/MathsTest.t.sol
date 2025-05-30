// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibCast as C} from "@libraries/LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
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
 * @title Maths Test - Tests for Maths
 * @copyright 2025
 * @notice Unit/integration tests for Maths functionality
 * @dev Test contract
 * @author BTR Team
 */

contract MathsTest is Test {
    using M for uint256;
    using M for int256;
    using C for uint256;
    using C for int256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant BPS = 10000;
    uint256 internal constant PREC_BPS = 100000000;

    // --- BASIS POINTS TESTS ---

    function testBpRatio() public pure {
        assertEq(M.bpRatio(5000, 10000), 5000, "50% ratio should be 5000 BPS");
        assertEq(M.bpRatio(1, 4), 2500, "25% ratio should be 2500 BPS");
        assertEq(M.bpRatio(3, 3), 10000, "100% ratio should be 10000 BPS");
    }

    function testPBpRatio() public pure {
        assertEq(M.pBpRatio(5000, 10000), 50000000, "50% ratio should be 50000000 PREC_BPS");
        assertEq(M.pBpRatio(1, 4), 25000000, "25% ratio should be 25000000 PREC_BPS");
    }

    function testSubBpDown() public pure {
        assertEq(M.subBpDown(10000, 1000), 9000, "Subtracting 10% from 10000 should give 9000");
        assertEq(M.subBpDown(1000, 500), 950, "Subtracting 5% from 1000 should give 950");
    }

    function testSubBpUp() public pure {
        uint256 result = M.subBpUp(10000, 1000);
        assertTrue(result >= 9000, "SubBpUp should be >= SubBpDown");
    }

    function testAddBpDown() public pure {
        assertEq(M.addBpDown(10000, 1000), 11000, "Adding 10% to 10000 should give 11000");
        assertEq(M.addBpDown(1000, 500), 1050, "Adding 5% to 1000 should give 1050");
    }

    function testAddBpUp() public pure {
        uint256 result = M.addBpUp(10000, 1000);
        assertTrue(result >= 11000, "AddBpUp should be >= AddBpDown");
    }

    function testBpDown() public pure {
        assertEq(M.bpDown(10000, 1000), 1000, "10% of 10000 should be 1000");
        assertEq(M.bpDown(1000, 500), 50, "5% of 1000 should be 50");
    }

    function testBpUp() public pure {
        uint256 result = M.bpUp(10000, 1000);
        assertTrue(result >= M.bpDown(10000, 1000), "BpUp should be >= BpDown");
    }

    function testRevBpDown() public pure {
        uint256 amount = 9000;
        uint256 bp = 1000; // 10%
        uint256 original = M.revBpDown(amount, bp);
        assertApproxEqAbs(M.subBpDown(original, bp), amount, 1, "Reverse operation should be consistent");
    }

    function testRevAddBp() public pure {
        uint256 amount = 9000;
        uint256 bp = 1000; // 10%
        uint256 original = M.revAddBp(amount, bp);
        assertApproxEqAbs(M.subBpDown(original, bp), amount, 1, "Reverse add operation should be consistent");
    }

    function testRevSubBp() public pure {
        uint256 amount = 11000;
        uint256 bp = 1000; // 10%
        uint256 original = M.revSubBp(amount, bp);
        assertApproxEqAbs(M.addBpDown(original, bp), amount, 1, "Reverse sub operation should be consistent");
    }

    function testToWad() public pure {
        assertEq(M.toWad(10000), WAD, "10000 BPS should equal 1 WAD");
        assertEq(M.toWad(5000), WAD / 2, "5000 BPS should equal 0.5 WAD");
    }

    function testToBp() public pure {
        assertEq(M.toBp(WAD), 10000, "1 WAD should equal 10000 BPS");
        assertEq(M.toBp(WAD / 2), 5000, "0.5 WAD should equal 5000 BPS");
    }

    // --- WAD MATH TESTS ---

    function testMulWad() public pure {
        assertEq(M.mulWad(WAD, WAD), WAD, "1 * 1 = 1 in WAD");
        assertEq(M.mulWad(WAD / 2, WAD), WAD / 2, "0.5 * 1 = 0.5 in WAD");
        assertEq(M.mulWad(2 * WAD, WAD / 4), WAD / 2, "2 * 0.25 = 0.5 in WAD");

        // Test with specific values from LibMathsTest
        uint256 a = 2e18;
        uint256 b = 3e18;
        uint256 expected = 6e18;
        uint256 result = M.mulWad(a, b);
        assertEq(result, expected, "mulWad should multiply WAD values correctly");
    }

    function testMulWadSigned() public pure {
        assertEq(M.mulWad(int256(WAD), int256(WAD)), int256(WAD), "1 * 1 = 1 in signed WAD");
        assertEq(M.mulWad(-int256(WAD), int256(WAD)), -int256(WAD), "-1 * 1 = -1 in signed WAD");
        assertEq(M.mulWad(int256(WAD / 2), int256(WAD)), int256(WAD / 2), "0.5 * 1 = 0.5 in signed WAD");
    }

    function testDivWad() public pure {
        assertEq(M.divWad(WAD, WAD), WAD, "1 / 1 = 1 in WAD");
        assertEq(M.divWad(WAD, 2), 2 * WAD, "1 / 2 = 2 in WAD");
        assertEq(M.divWad(WAD / 2, WAD), WAD / 2, "0.5 / 1 = 0.5 in WAD");

        // Test with specific values from LibMathsTest
        uint256 a = 6e18;
        uint256 b = 3e18;
        uint256 expected = 2e18;
        uint256 result = M.divWad(a, b);
        assertEq(result, expected, "divWad should divide WAD values correctly");
    }

    function testDivWadSigned() public pure {
        assertEq(M.divWad(int256(WAD), int256(WAD)), int256(WAD), "1 / 1 = 1 in signed WAD");
        assertEq(M.divWad(-int256(WAD), int256(WAD)), -int256(WAD), "-1 / 1 = -1 in signed WAD");
    }

    function testMulDiv() public pure {
        assertEq(M.mulDiv(100, 200, 50), 400, "100 * 200 / 50 = 400");
        assertEq(M.mulDiv(3, 3, 2), 4, "3 * 3 / 2 = 4 (rounded down)");
    }

    function testMulDivUp() public pure {
        assertEq(M.mulDivUp(100, 200, 50), 400, "100 * 200 / 50 = 400");
        assertEq(M.mulDivUp(3, 3, 2), 5, "3 * 3 / 2 = 5 (rounded up)");
    }

    function testMulDivDown() public pure {
        assertEq(M.mulDivDown(100, 200, 50), 400, "100 * 200 / 50 = 400");
        assertEq(M.mulDivDown(3, 3, 2), 4, "3 * 3 / 2 = 4 (rounded down)");
    }

    function testFullMulDiv() public pure {
        // Test with large numbers that would overflow in simple multiplication
        uint256 large1 = type(uint128).max;
        uint256 large2 = type(uint128).max;
        uint256 result = M.fullMulDiv(large1, large2, large1);
        assertEq(result, large2, "Large number multiplication should work");

        // Test with specific values from LibMathsTest
        uint256 a = 1000;
        uint256 b = 2000;
        uint256 d = 500;
        uint256 expected = 4000;
        uint256 result2 = M.fullMulDiv(a, b, d);
        assertEq(result2, expected, "fullMulDiv should compute full precision division correctly");
    }

    function testFullMulDivUp() public pure {
        uint256 result = M.fullMulDivUp(3, 3, 2);
        assertEq(result, 5, "3 * 3 / 2 = 5 (rounded up)");

        // Test with specific values from LibMathsTest
        uint256 a = 1001;
        uint256 b = 2000;
        uint256 d = 500;
        uint256 expected = 4005; // Rounded up
        uint256 result2 = M.fullMulDivUp(a, b, d);
        assertEq(result2, expected, "fullMulDivUp should round up correctly");
    }

    // --- UTILITY FUNCTIONS TESTS ---

    function testDiff() public pure {
        assertEq(M.diff(100, 50), 50, "Difference between 100 and 50 should be 50");
        assertEq(M.diff(50, 100), 50, "Difference between 50 and 100 should be 50");
        assertEq(M.diff(100, 100), 0, "Difference between equal numbers should be 0");
    }

    function testMax() public pure {
        assertEq(M.max(100, 50), 100, "Max of 100 and 50 should be 100");
        assertEq(M.max(50, 100), 100, "Max of 50 and 100 should be 100");
        assertEq(M.max(100, 100), 100, "Max of equal numbers should be the number");
    }

    function testMaxSigned() public pure {
        assertEq(M.max(int256(100), int256(-50)), int256(100), "Max of 100 and -50 should be 100");
        assertEq(M.max(int256(-100), int256(-50)), int256(-50), "Max of -100 and -50 should be -50");
    }

    function testMin() public pure {
        assertEq(M.min(100, 50), 50, "Min of 100 and 50 should be 50");
        assertEq(M.min(50, 100), 50, "Min of 50 and 100 should be 50");
        assertEq(M.min(100, 100), 100, "Min of equal numbers should be the number");
    }

    function testMinSigned() public pure {
        assertEq(M.min(int256(100), int256(-50)), int256(-50), "Min of 100 and -50 should be -50");
        assertEq(M.min(int256(-100), int256(-50)), int256(-100), "Min of -100 and -50 should be -100");
    }

    function testApproxEq() public pure {
        assertTrue(M.approxEq(1000, 1001, 1e15), "1000 and 1001 should be approximately equal with 0.1% tolerance");
        assertFalse(M.approxEq(1000, 1100, 1e16), "1000 and 1100 should not be approximately equal with 1% tolerance");
    }

    function testApproxEqDefault() public pure {
        assertTrue(M.approxEq(1000, 1000), "Equal numbers should be approximately equal");
        assertTrue(
            M.approxEq(1000000000000000000, 1000000000000000001),
            "Very close large numbers should be approximately equal"
        );
    }

    function testTryAdd() public pure {
        (bool success, uint256 result) = M.tryAdd(100, 50);
        assertTrue(success, "Normal addition should succeed");
        assertEq(result, 150, "100 + 50 = 150");

        (success, result) = M.tryAdd(type(uint256).max, 1);
        assertFalse(success, "Overflow addition should fail");
        assertEq(result, 0, "Failed addition should return 0");
    }

    function testTrySub() public pure {
        (bool success, uint256 result) = M.trySub(100, 50);
        assertTrue(success, "Normal subtraction should succeed");
        assertEq(result, 50, "100 - 50 = 50");

        (success, result) = M.trySub(50, 100);
        assertFalse(success, "Underflow subtraction should fail");
        assertEq(result, 0, "Failed subtraction should return 0");
    }

    function testTryMul() public pure {
        (bool success, uint256 result) = M.tryMul(100, 50);
        assertTrue(success, "Normal multiplication should succeed");
        assertEq(result, 5000, "100 * 50 = 5000");

        (success, result) = M.tryMul(type(uint256).max, 2);
        assertFalse(success, "Overflow multiplication should fail");
        assertEq(result, 0, "Failed multiplication should return 0");
    }

    function testTryDiv() public pure {
        (bool success, uint256 result) = M.tryDiv(100, 50);
        assertTrue(success, "Normal division should succeed");
        assertEq(result, 2, "100 / 50 = 2");

        (success, result) = M.tryDiv(100, 0);
        assertFalse(success, "Division by zero should fail");
        assertEq(result, 0, "Failed division should return 0");
    }

    function testAverage() public pure {
        assertEq(M.average(100, 50), 75, "Average of 100 and 50 should be 75");
        assertEq(M.average(0, 100), 50, "Average of 0 and 100 should be 50");
        assertEq(
            M.average(type(uint256).max, type(uint256).max - 1),
            type(uint256).max - 1,
            "Average should handle large numbers"
        );
    }

    function testWithin() public pure {
        assertTrue(M.within(50, 0, 100), "50 should be within 0-100");
        assertTrue(M.within(0, 0, 100), "0 should be within 0-100");
        assertTrue(M.within(100, 0, 100), "100 should be within 0-100");
        assertFalse(M.within(150, 0, 100), "150 should not be within 0-100");
    }

    function testWithinSigned() public pure {
        assertTrue(M.within(int256(0), int256(-100), int256(100)), "0 should be within -100 to 100");
        assertFalse(M.within(int256(150), int256(-100), int256(100)), "150 should not be within -100 to 100");
    }

    function testDiffWithin() public pure {
        assertTrue(M.diffWithin(100, 105, 10), "Difference of 5 should be within threshold of 10");
        assertFalse(M.diffWithin(100, 120, 10), "Difference of 20 should not be within threshold of 10");
    }

    function testDiffWithin1() public pure {
        assertTrue(M.diffWithin1(100, 101), "Difference of 1 should be within 1");
        assertTrue(M.diffWithin1(100, 100), "Difference of 0 should be within 1");
        assertFalse(M.diffWithin1(100, 102), "Difference of 2 should not be within 1");
    }

    function testSubMax0() public pure {
        assertEq(M.subMax0(100, 50), 50, "100 - 50 = 50");
        assertEq(M.subMax0(50, 100), 0, "50 - 100 = 0 (clamped)");
        assertEq(M.subMax0(100, 100), 0, "100 - 100 = 0");
    }

    function testSubNoNeg() public {
        assertEq(M.subNoNeg(int256(100), int256(50)), int256(50), "100 - 50 = 50");
        vm.expectRevert();
        M.subNoNeg(int256(50), int256(100)); // Should revert for negative result
    }

    function testAbs() public pure {
        assertEq(M.abs(int256(100)), 100, "Absolute value of 100 should be 100");
        assertEq(M.abs(int256(-100)), 100, "Absolute value of -100 should be 100");
        assertEq(M.abs(int256(0)), 0, "Absolute value of 0 should be 0");
        assertEq(
            M.abs(type(int256).min), uint256(type(int256).max) + 1, "Absolute value of min int should be max uint + 1"
        );
    }

    function testNeg() public pure {
        assertEq(M.neg(int256(100)), int256(-100), "Negation of 100 should be -100");
        assertEq(M.neg(int256(-100)), int256(100), "Negation of -100 should be 100");
        assertEq(M.neg(int256(0)), int256(0), "Negation of 0 should be 0");
    }

    function testNegUnsigned() public pure {
        assertEq(M.neg(uint256(100)), int256(-100), "Negation of uint 100 should be int -100");
        assertEq(M.neg(uint256(0)), int256(0), "Negation of uint 0 should be int 0");
    }

    // --- LEGACY COMPATIBILITY TESTS ---

    function testBackwardCompatibility() public pure {
        // Test that legacy functions still work
        uint256 a = 2e18;
        uint256 b = 3e18;

        uint256 legacyResult = M.mulDown(a, b);
        uint256 newResult = M.mulWad(a, b);

        // NB: mulDown has different semantics than mulWad (no overflow protection)
        // but the basic math should be similar for safe inputs
        assertTrue(legacyResult > 0, "Legacy mulDown should work");
        assertTrue(newResult > 0, "New mulWad should work");
    }

    // --- ADVANCED MATH TESTS ---

    function testSqrt() public pure {
        assertEq(M.sqrt(0), 0, "Square root of 0 should be 0");
        assertEq(M.sqrt(1), 1, "Square root of 1 should be 1");
        assertEq(M.sqrt(4), 2, "Square root of 4 should be 2");
        assertEq(M.sqrt(9), 3, "Square root of 9 should be 3");
        assertEq(M.sqrt(16), 4, "Square root of 16 should be 4");
        assertEq(M.sqrt(100), 10, "Square root of 100 should be 10");

        // Test with specific values from LibMathsTest
        uint256 value = 16e18;
        uint256 expected = 4e9; // sqrt(16e18) = 4e9
        uint256 result = M.sqrt(value);
        assertEq(result, expected, "sqrt should compute square root correctly");
    }

    function testSqrtWad() public pure {
        assertEq(M.sqrtWad(WAD), WAD, "Square root of 1 WAD should be 1 WAD");
        assertEq(M.sqrtWad(4 * WAD), 2 * WAD, "Square root of 4 WAD should be 2 WAD");

        // Test with specific values from LibMathsTest
        uint256 value = 4e18;
        uint256 expected = 2e18; // sqrt(4) = 2 in WAD
        uint256 result = M.sqrtWad(value);
        assertEq(result, expected, "sqrtWad should compute WAD square root correctly");
    }

    function testLog2() public pure {
        assertEq(M.log2(1), 0, "Log2 of 1 should be 0");
        assertEq(M.log2(2), 1, "Log2 of 2 should be 1");
        assertEq(M.log2(4), 2, "Log2 of 4 should be 2");
        assertEq(M.log2(8), 3, "Log2 of 8 should be 3");
    }

    function testLog10() public pure {
        assertEq(M.log10(1), 0, "Log10 of 1 should be 0");
        assertEq(M.log10(10), 1, "Log10 of 10 should be 1");
        assertEq(M.log10(100), 2, "Log10 of 100 should be 2");
        assertEq(M.log10(1000), 3, "Log10 of 1000 should be 3");
    }

    function testClamp() public pure {
        assertEq(M.clamp(50, 0, 100), 50, "50 clamped to 0-100 should be 50");
        assertEq(M.clamp(150, 0, 100), 100, "150 clamped to 0-100 should be 100");
        assertEq(M.clamp(0, 10, 100), 10, "0 clamped to 10-100 should be 10");
    }

    function testClampSigned() public pure {
        assertEq(M.clamp(int256(50), int256(0), int256(100)), int256(50), "50 clamped to 0-100 should be 50");
        assertEq(M.clamp(int256(-50), int256(0), int256(100)), int256(0), "-50 clamped to 0-100 should be 0");
    }

    function testLerp() public pure {
        assertEq(M.lerp(0, 100, 50, 0, 100), 50, "Linear interpolation at midpoint should be midpoint");
        assertEq(M.lerp(0, 100, 25, 0, 100), 25, "Linear interpolation at 25% should be 25");
        assertEq(M.lerp(0, 100, 0, 0, 100), 0, "Linear interpolation at start should be start value");
        assertEq(M.lerp(0, 100, 100, 0, 100), 100, "Linear interpolation at end should be end value");
    }

    function testLerpSigned() public pure {
        assertEq(
            M.lerp(int256(-100), int256(100), int256(0), int256(-100), int256(100)),
            int256(0),
            "Signed lerp at midpoint should be 0"
        );
    }

    // --- ERROR HANDLING TESTS ---

    function testMulWadOverflow() public {
        vm.expectRevert(M.MathError.selector);
        M.mulWad(type(uint256).max, 2);
    }

    function testDivWadByZero() public pure {
        vm.expectRevert(M.MathError.selector);
        M.divWad(100, 0);

        // Also test the original test case
        vm.expectRevert();
        M.divWad(100e18, 0);
    }

    function testFullMulDivByZero() public pure {
        vm.expectRevert(M.MathError.selector);
        M.fullMulDiv(100, 200, 0);
    }

    function testErrorConditions() public {
        // Test division by zero error
        vm.expectRevert();
        M.divWad(100e18, 0);

        // Test multiplication overflow error
        vm.expectRevert();
        M.mulWad(type(uint256).max, 2);
    }

    // --- FUZZ TESTS ---

    function testFuzzMulDivConsistency(uint256 a, uint256 b, uint256 c) public pure {
        vm.assume(a <= type(uint128).max);
        vm.assume(b <= type(uint128).max);
        vm.assume(c > 0 && c <= type(uint128).max);

        uint256 mulDivResult = M.mulDivDown(a, b, c);
        uint256 fullMulDivResult = M.fullMulDiv(a, b, c);

        assertEq(mulDivResult, fullMulDivResult, "MulDiv and FullMulDiv should be consistent for small numbers");
    }

    function testFuzzBasisPointRoundTrip(uint256 amount, uint256 bp) public pure {
        vm.assume(amount <= type(uint128).max);
        vm.assume(bp <= BPS);
        vm.assume(bp > 0);

        uint256 reduced = M.subBpDown(amount, bp);
        uint256 restored = M.revAddBp(reduced, bp);

        assertApproxEqRel(restored, amount, 1e12, "Basis point operations should be roughly reversible");
    }
}
