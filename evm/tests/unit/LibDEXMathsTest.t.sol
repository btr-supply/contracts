// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {LibDEXMaths} from "@libraries/LibDEXMaths.sol";
import {LibMaths} from "@libraries/LibMaths.sol";
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
 * @title LibDEXMaths Test - Tests for DEX mathematical functions
 * @copyright 2025
 * @notice Unit tests for DEX-specific mathematical operations
 * @dev Test contract for LibDEXMaths functionality
 * @author BTR Team
 */

contract LibDEXMathsTest is Test {
    uint160 constant MIN_SQRT = 4295128739;
    uint160 constant MAX_SQRT = 1461446703485210103287273052203988822378723970342;
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = 887272;

    // --- PRICE CONVERSION TESTS ---

    function testInvertPriceX96() public pure {
        uint160 priceX96 = 79228162514264337593543950336; // 1.0 in Q64.96
        uint160 inverted = LibDEXMaths.invertPriceX96(priceX96);
        assertEq(inverted, priceX96, "Inverting 1.0 should return 1.0");

        uint160 doublePrice = 158456325028528675187087900672; // 2.0 in Q64.96
        uint160 halfPrice = LibDEXMaths.invertPriceX96(doublePrice);
        assertApproxEqRel(halfPrice, priceX96 / 2, 1e12, "Inverting 2.0 should return 0.5");
    }

    function testPriceX96ToPrice() public pure {
        uint160 oneX96 = 79228162514264337593543950336; // 1.0 in Q64.96
        uint256 price = LibDEXMaths.priceX96ToPrice(oneX96);
        assertApproxEqRel(price, 1e18, 1e12, "Price should be approximately 1e18");

        uint160 fourX96 = 158456325028528675187087900672; // 2.0 in Q64.96
        uint256 priceSquared = LibDEXMaths.priceX96ToPrice(fourX96);
        assertApproxEqRel(priceSquared, 4e18, 1e12, "Price should be approximately 4e18");
    }

    function testPriceToPriceX96() public pure {
        uint256 price = 1e18; // 1.0 in WAD
        uint160 priceX96 = LibDEXMaths.priceToPriceX96(price);
        assertApproxEqRel(priceX96, 79228162514264337593543950336, 1e12, "Should convert to approximately 1.0 in Q64.96");

        uint256 price4 = 4e18; // 4.0 in WAD
        uint160 priceX96_2 = LibDEXMaths.priceToPriceX96(price4);
        assertApproxEqRel(priceX96_2, 158456325028528675187087900672, 1e12, "Should convert to approximately 2.0 in Q64.96");
    }

    function testPriceConversionRoundTrip() public pure {
        uint256 originalPrice = 1e18;
        uint160 priceX96 = LibDEXMaths.priceToPriceX96(originalPrice);
        uint256 convertedBack = LibDEXMaths.priceX96ToPrice(priceX96);
        assertApproxEqRel(convertedBack, originalPrice, 1e10, "Round trip conversion should be consistent");

        uint256 originalPrice2 = 5e17; // 0.5 in WAD
        uint160 priceX96_2 = LibDEXMaths.priceToPriceX96(originalPrice2);
        uint256 convertedBack2 = LibDEXMaths.priceX96ToPrice(priceX96_2);
        assertApproxEqRel(convertedBack2, originalPrice2, 1e10, "Round trip conversion should be consistent for 0.5");
    }

    // --- TICK CONVERSION TESTS ---

    function testTickToPriceX96V3() public pure {
        int24 tick0 = 0;
        uint160 sqrtPrice0 = LibDEXMaths.tickToPriceX96V3(tick0);
        assertApproxEqRel(sqrtPrice0, 79228162514264337593543950336, 1e12, "Tick 0 should give sqrt(1.0001^0) = 1.0");

        int24 tick1 = 1;
        uint160 sqrtPrice1 = LibDEXMaths.tickToPriceX96V3(tick1);
        assertTrue(sqrtPrice1 > sqrtPrice0, "Positive tick should give higher sqrt price");

        int24 tickNeg1 = -1;
        uint160 sqrtPriceNeg1 = LibDEXMaths.tickToPriceX96V3(tickNeg1);
        assertTrue(sqrtPriceNeg1 < sqrtPrice0, "Negative tick should give lower sqrt price");
    }

    function testPriceX96ToTickV3() public pure {
        uint160 sqrtPrice1 = 79228162514264337593543950336; // sqrt(1.0) in Q64.96
        int24 tick = LibDEXMaths.priceX96ToTickV3(sqrtPrice1);
        assertEq(tick, 0, "sqrt(1.0) should give tick 0");

        uint160 sqrtPrice2 = sqrtPrice1 * 2; // Higher price
        int24 tick2 = LibDEXMaths.priceX96ToTickV3(sqrtPrice2);
        assertTrue(tick2 > 0, "Higher sqrt price should give positive tick");
    }

    function testTickConversionRoundTrip() public pure {
        int24 originalTick = 1000;
        uint160 sqrtPrice = LibDEXMaths.tickToPriceX96V3(originalTick);
        int24 convertedTick = LibDEXMaths.priceX96ToTickV3(sqrtPrice);
        assertApproxEqAbs(convertedTick, originalTick, 1, "Round trip tick conversion should be accurate");

        int24 originalTickNeg = -500;
        uint160 sqrtPriceNeg = LibDEXMaths.tickToPriceX96V3(originalTickNeg);
        int24 convertedTickNeg = LibDEXMaths.priceX96ToTickV3(sqrtPriceNeg);
        assertApproxEqAbs(convertedTickNeg, originalTickNeg, 1, "Round trip conversion should work for negative ticks");
    }

    // --- LIQUIDITY MATH TESTS ---

    function testLiquidityToAmount0PriceX96V3() public pure {
        uint160 priceA = 79228162514264337593543950336; // 1.0
        uint160 priceB = 112045541949572279837463876454; // ~2.0
        uint128 liquidity = 1e18;

        uint256 amount0 = LibDEXMaths.liquidityToAmount0PriceX96V3(priceA, priceB, liquidity);
        assertTrue(amount0 > 0, "Amount0 should be positive");
    }

    function testLiquidityToAmount1PriceX96V3() public pure {
        uint160 priceA = 79228162514264337593543950336; // 1.0
        uint160 priceB = 112045541949572279837463876454; // ~2.0
        uint128 liquidity = 1e18;

        uint256 amount1 = LibDEXMaths.liquidityToAmount1PriceX96V3(priceA, priceB, liquidity);
        assertTrue(amount1 > 0, "Amount1 should be positive");
    }

    function testAmountsToLiquidityPriceX96V3() public pure {
        uint160 current = 88896105732595182886075945882; // ~1.5
        uint160 priceA = 79228162514264337593543950336; // 1.0
        uint160 priceB = 112045541949572279837463876454; // ~2.0
        uint256 amount0 = 1e18;
        uint256 amount1 = 1e18;

        uint128 liquidity = LibDEXMaths.amountsToLiquidityPriceX96V3(current, priceA, priceB, amount0, amount1);
        assertTrue(liquidity > 0, "Liquidity should be positive");
    }

    function testLiquidityToAmountsTickV3() public pure {
        int24 currentTick = 0;
        int24 lowerTick = -1000;
        int24 upperTick = 1000;
        uint128 liquidity = 1e18;

        (uint256 amount0, uint256 amount1) = LibDEXMaths.liquidityToAmountsTickV3(currentTick, lowerTick, upperTick, liquidity);
        assertTrue(amount0 > 0 || amount1 > 0, "At least one amount should be positive");
    }

    // --- UTILITY TESTS ---

    function testValidateTickSpacing() public pure {
        assertTrue(LibDEXMaths.validateTickSpacing(60, -120, 120), "Valid tick spacing should return true");
        assertFalse(LibDEXMaths.validateTickSpacing(60, -121, 120), "Invalid lower tick should return false");
        assertFalse(LibDEXMaths.validateTickSpacing(60, -120, 121), "Invalid upper tick should return false");
        assertFalse(LibDEXMaths.validateTickSpacing(60, 120, -120), "Reversed ticks should return false");
    }

    function testRoundTickToSpacing() public pure {
        assertEq(LibDEXMaths.roundTickToSpacing(123, 60, true), 180, "Round up should work");
        assertEq(LibDEXMaths.roundTickToSpacing(123, 60, false), 120, "Round down should work");
        assertEq(LibDEXMaths.roundTickToSpacing(120, 60, true), 120, "Exact tick should remain unchanged");
        assertEq(LibDEXMaths.roundTickToSpacing(120, 60, false), 120, "Exact tick should remain unchanged");
    }

    function testDeviationState() public pure {
        uint160 current = 100e18;
        uint160 mean = 95e18;
        uint256 maxDev = 10000000; // 10% in PREC_BPS

        (bool isStale, uint256 deviation) = LibDEXMaths.deviationState(current, mean, maxDev);
        assertFalse(isStale, "5% deviation should not be stale with 10% threshold");
        assertTrue(deviation > 0, "Deviation should be positive");

        // Test with larger deviation
        current = 120e18;
        (isStale, deviation) = LibDEXMaths.deviationState(current, mean, maxDev);
        assertTrue(isStale, "25% deviation should be stale with 10% threshold");
    }

    function testPriceX96RangeToTicks() public pure {
        uint160 lowerPrice = 79228162514264337593543950336; // 1.0
        uint160 upperPrice = 112045541949572279837463876454; // ~2.0
        int24 tickSpacing = 60;

        (int24 lowerTick, int24 upperTick) = LibDEXMaths.priceX96RangeToTicks(lowerPrice, upperPrice, tickSpacing);
        assertTrue(lowerTick < upperTick, "Lower tick should be less than upper tick");
        assertTrue(lowerTick % tickSpacing == 0, "Lower tick should be aligned to spacing");
        assertTrue(upperTick % tickSpacing == 0, "Upper tick should be aligned to spacing");
    }

    // --- BOUNDARY TESTS ---

    function testBoundaryValues() public pure {
        // Test minimum tick
        uint160 minSqrtPrice = LibDEXMaths.tickToPriceX96V3(MIN_TICK);
        assertTrue(minSqrtPrice >= MIN_SQRT, "Min tick should produce valid sqrt price");

        // Test maximum tick
        uint160 maxSqrtPrice = LibDEXMaths.tickToPriceX96V3(MAX_TICK);
        assertTrue(maxSqrtPrice <= MAX_SQRT, "Max tick should produce valid sqrt price");

        // Test sqrt price boundaries
        int24 minTickFromSqrt = LibDEXMaths.priceX96ToTickV3(MIN_SQRT);
        assertTrue(minTickFromSqrt >= MIN_TICK, "Min sqrt price should produce valid tick");

        int24 maxTickFromSqrt = LibDEXMaths.priceX96ToTickV3(MAX_SQRT);
        assertTrue(maxTickFromSqrt <= MAX_TICK, "Max sqrt price should produce valid tick");
    }

    // --- ERROR HANDLING TESTS ---

    function testInvalidInputs() public {
        // Test zero sqrt price conversion
        vm.expectRevert();
        LibDEXMaths.priceX96ToTickV3(0);

        // Test sqrt price too high
        vm.expectRevert();
        LibDEXMaths.priceX96ToTickV3(type(uint160).max);

        // Test invalid tick range
        vm.expectRevert();
        LibDEXMaths.tickToPriceX96V3(MIN_TICK - 1);

        vm.expectRevert();
        LibDEXMaths.tickToPriceX96V3(MAX_TICK + 1);
    }

    // --- FUZZ TESTS ---

    function testFuzzTickConversion(int24 tick) public pure {
        vm.assume(tick >= MIN_TICK && tick <= MAX_TICK);

        uint160 sqrtPrice = LibDEXMaths.tickToPriceX96V3(tick);
        assertTrue(sqrtPrice >= MIN_SQRT && sqrtPrice <= MAX_SQRT, "Sqrt price should be in valid range");

        int24 convertedTick = LibDEXMaths.priceX96ToTickV3(sqrtPrice);
        assertApproxEqAbs(convertedTick, tick, 1, "Fuzz tick conversion should be accurate");
    }

    function testFuzzPriceConversion(uint160 priceX96) public pure {
        vm.assume(priceX96 >= MIN_SQRT && priceX96 <= MAX_SQRT);

        uint256 price = LibDEXMaths.priceX96ToPrice(priceX96);
        uint160 convertedPriceX96 = LibDEXMaths.priceToPriceX96(price);

        assertApproxEqRel(convertedPriceX96, priceX96, 1e10, "Fuzz price conversion should be accurate");
    }
}
