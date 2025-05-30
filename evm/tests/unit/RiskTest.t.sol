// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {RiskModel, WeightModel, LiquidityModel, SlippageModel} from "@/BTRTypes.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibRisk as R} from "@libraries/LibRisk.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import "forge-std/Test.sol";
import {RiskModelFacet} from "@facets/RiskModelFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Risk Test - Tests for Risk
 * @copyright 2025
 * @notice Unit/integration tests for Risk functionality
 * @dev Test contract
 * @author BTR Team
 */

contract RiskTest is BaseDiamondTest {
    using U for uint32;
    using M for uint256;

    RiskModelFacet internal riskFacet;

    // Test constants
    uint16 internal constant MAX_SCORE = 10000;
    uint16 internal constant MAX_WEIGHT = 10000;

    function setUp() public override {
        super.setUp();
        riskFacet = RiskModelFacet(diamond);

        vm.prank(admin);
        riskFacet.initializeRiskModel();
    }

    // --- DEFAULT MODEL TESTS ---

    function testDefaultRiskModel() public {
        RiskModel memory defaultModel = riskFacet.defaultRiskModel();

        assertEq(defaultModel.weight.defaultCScore, MAX_SCORE / 2, "Default cScore should be 50%");
        assertEq(defaultModel.weight.scoreAmplifierBp, 1.5e4, "Default score amplifier should be 1.5");
        assertEq(defaultModel.weight.minMaxBp, 0.25e4, "Default min max should be 25%");
        assertEq(defaultModel.weight.maxBp, MAX_WEIGHT, "Default max should be 100%");
        assertEq(defaultModel.weight.diversificationFactorBp, 0.3e4, "Default diversification factor should be 0.3");

        assertEq(defaultModel.liquidity.minRatioBp, 0.05e4, "Default min ratio should be 5%");
        assertEq(defaultModel.liquidity.tvlExponentBp, 0.03e4, "Default TVL exponent should be 0.03");
        assertEq(defaultModel.liquidity.tvlFactorBp, 0.3e4, "Default TVL factor should be 0.3");
        assertEq(defaultModel.liquidity.lowOffsetBp, 0.5e4, "Default low offset should be 0.5");
        assertEq(defaultModel.liquidity.highOffsetBp, 0.5e4, "Default high offset should be 0.5");

        assertEq(defaultModel.slippage.minSlippageBp, 10, "Default min slippage should be 0.1%");
        assertEq(defaultModel.slippage.maxSlippageBp, 500, "Default max slippage should be 5%");
        assertEq(defaultModel.slippage.amplificationBp, 5000, "Default amplification should be 5000");
    }

    function testDefaultWeightModel() public {
        WeightModel memory weightModel = riskFacet.defaultWeightModel();

        assertEq(weightModel.defaultCScore, MAX_SCORE / 2, "Default cScore should be 50%");
        assertEq(weightModel.scoreAmplifierBp, 1.5e4, "Default score amplifier should be 1.5");
        assertEq(weightModel.minMaxBp, 0.25e4, "Default min max should be 25%");
        assertEq(weightModel.maxBp, MAX_WEIGHT, "Default max should be 100%");
        assertEq(weightModel.diversificationFactorBp, 0.3e4, "Default diversification factor should be 0.3");
    }

    function testDefaultLiquidityModel() public {
        LiquidityModel memory liquidityModel = riskFacet.defaultLiquidityModel();

        assertEq(liquidityModel.minRatioBp, 0.05e4, "Default min ratio should be 5%");
        assertEq(liquidityModel.tvlExponentBp, 0.03e4, "Default TVL exponent should be 0.03");
        assertEq(liquidityModel.tvlFactorBp, 0.3e4, "Default TVL factor should be 0.3");
        assertEq(liquidityModel.lowOffsetBp, 0.5e4, "Default low offset should be 0.5");
        assertEq(liquidityModel.highOffsetBp, 0.5e4, "Default high offset should be 0.5");
    }

    function testDefaultSlippageModel() public {
        SlippageModel memory slippageModel = riskFacet.defaultSlippageModel();

        assertEq(slippageModel.minSlippageBp, 10, "Default min slippage should be 0.1%");
        assertEq(slippageModel.maxSlippageBp, 500, "Default max slippage should be 5%");
        assertEq(slippageModel.amplificationBp, 5000, "Default amplification should be 5000");
    }

    // --- VALIDATION TESTS ---

    function testValidateWeightModel() public {
        WeightModel memory validModel = riskFacet.defaultWeightModel();
        riskFacet.validateWeightModel(validModel); // Should not revert

        // Test invalid score amplifier (too low)
        WeightModel memory invalidModel = validModel;
        invalidModel.scoreAmplifierBp = 0.5e4; // 0.5
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateWeightModel(invalidModel);

        // Test invalid score amplifier (too high)
        invalidModel = validModel;
        invalidModel.scoreAmplifierBp = 3e4; // 3.0
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateWeightModel(invalidModel);

        // Test invalid max weight
        invalidModel = validModel;
        invalidModel.maxBp = 15000; // 150%
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateWeightModel(invalidModel);
    }

    function testValidateLiquidityModel() public {
        LiquidityModel memory validModel = riskFacet.defaultLiquidityModel();
        riskFacet.validateLiquidityModel(validModel); // Should not revert

        // Test invalid min ratio (too high)
        LiquidityModel memory invalidModel = validModel;
        invalidModel.minRatioBp = 15000; // 150%
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateLiquidityModel(invalidModel);

        // Test invalid TVL exponent (too low)
        invalidModel = validModel;
        invalidModel.tvlExponentBp = 0.001e4; // 0.001
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateLiquidityModel(invalidModel);
    }

    function testValidateSlippageModel() public {
        SlippageModel memory validModel = riskFacet.defaultSlippageModel();
        riskFacet.validateSlippageModel(validModel); // Should not revert

        // Test invalid slippage range (min >= max)
        SlippageModel memory invalidModel = validModel;
        invalidModel.minSlippageBp = 600; // Greater than max
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateSlippageModel(invalidModel);

        // Test invalid max slippage (too high)
        invalidModel = validModel;
        invalidModel.maxSlippageBp = 1500; // 15%
        vm.expectRevert(Errors.UnexpectedInput.selector);
        riskFacet.validateSlippageModel(invalidModel);
    }

    function testValidateRiskModel() public {
        RiskModel memory validModel = riskFacet.defaultRiskModel();
        riskFacet.validateRiskModel(validModel); // Should not revert
    }

    // --- CONFIGURATION TESTS ---

    function testSetRiskModel() public {
        RiskModel memory newModel = riskFacet.defaultRiskModel();
        newModel.weight.defaultCScore = 6000; // 60%

        vm.prank(admin);
        riskFacet.setRiskModel(newModel);

        RiskModel memory retrievedModel = riskFacet.riskModel();
        assertEq(retrievedModel.weight.defaultCScore, 6000, "Risk model should be updated");
    }

    function testSetWeightModel() public {
        WeightModel memory newWeightModel = riskFacet.defaultWeightModel();
        newWeightModel.defaultCScore = 7000; // 70%

        vm.prank(admin);
        riskFacet.setWeightModel(newWeightModel);

        WeightModel memory retrievedModel = riskFacet.weightModel();
        assertEq(retrievedModel.defaultCScore, 7000, "Weight model should be updated");
    }

    function testSetLiquidityModel() public {
        LiquidityModel memory newLiquidityModel = riskFacet.defaultLiquidityModel();
        newLiquidityModel.minRatioBp = 0.1e4; // 10%

        vm.prank(admin);
        riskFacet.setLiquidityModel(newLiquidityModel);

        LiquidityModel memory retrievedModel = riskFacet.liquidityModel();
        assertEq(retrievedModel.minRatioBp, 0.1e4, "Liquidity model should be updated");
    }

    function testSetSlippageModel() public {
        SlippageModel memory newSlippageModel = riskFacet.defaultSlippageModel();
        newSlippageModel.minSlippageBp = 20; // 0.2%

        vm.prank(admin);
        riskFacet.setSlippageModel(newSlippageModel);

        SlippageModel memory retrievedModel = riskFacet.slippageModel();
        assertEq(retrievedModel.minSlippageBp, 20, "Slippage model should be updated");
    }

    function testSetPoolCScore() public {
        bytes32 poolId = keccak256("test-pool");
        uint16 cScore = 8000; // 80%

        // This would normally require the pool to exist in the registry
        // For testing, we might need to mock the pool existence
        vm.expectRevert(); // Expected to revert because pool doesn't exist
        vm.prank(manager);
        riskFacet.setPoolCScore(poolId, cScore);
    }

    // --- COMPUTATIONAL TESTS ---

    function testComponentMaxWeightBp() public {
        uint256 components = 4;
        uint16 minMaxBp = 2500; // 25%
        uint16 diversificationFactorBp = 1.5e4; // 1.5
        uint16 maxBp = 8000; // 80% absolute max

        uint256 maxWeight = R.componentMaxWeightBp(components, minMaxBp, diversificationFactorBp, maxBp);

        assertTrue(maxWeight >= minMaxBp, "Max weight should be at least min max");
        assertTrue(maxWeight <= maxBp, "Max weight should not exceed absolute max");
        assertTrue(maxWeight <= MAX_WEIGHT, "Max weight should not exceed 100%");
    }

    function testCScore() public {
        // Test single score
        uint16[] memory singleScore = new uint16[](1);
        singleScore[0] = 8000;
        assertEq(R.cScore(singleScore), 8000, "Single score should return itself");

        // Test multiple equal scores
        uint16[] memory equalScores = new uint16[](3);
        equalScores[0] = 6000;
        equalScores[1] = 6000;
        equalScores[2] = 6000;
        assertEq(R.cScore(equalScores), 6000, "Equal scores should return the same value");

        // Test with zero score (should return 0)
        uint16[] memory withZero = new uint16[](2);
        withZero[0] = 8000;
        withZero[1] = 0;
        assertEq(R.cScore(withZero), 0, "Any zero score should make composite zero");

        // Test empty array
        uint16[] memory empty = new uint16[](0);
        assertEq(R.cScore(empty), 0, "Empty array should return 0");
    }

    function testTargetWeights() public {
        uint16[] memory cScores = new uint16[](3);
        cScores[0] = 8000; // 80%
        cScores[1] = 6000; // 60%
        cScores[2] = 4000; // 40%

        uint16 maxWeightBp = 5000; // 50%
        uint16 totalWeightBp = 10000; // 100%
        uint16 scoreAmplifierBp = 1e4; // 1.0 (linear)

        uint256[] memory weights = R.targetWeights(cScores, maxWeightBp, totalWeightBp, scoreAmplifierBp);

        assertEq(weights.length, 3, "Should return same number of weights as scores");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
            assertTrue(weights[i] <= maxWeightBp, "Each weight should be within max limit");
        }

        assertEq(totalWeight, totalWeightBp, "Total weights should sum to target total");
        assertTrue(weights[0] >= weights[1], "Higher score should get higher weight");
        assertTrue(weights[1] >= weights[2], "Higher score should get higher weight");
    }

    function testTargetAllocations() public {
        uint16[] memory cScores = new uint16[](2);
        cScores[0] = 8000; // 80%
        cScores[1] = 4000; // 40%

        uint256 amount = 1000e18;
        uint16 maxWeightBp = 10000; // 100%
        uint16 scoreAmplifierBp = 1e4; // 1.0 (linear)

        uint256[] memory allocations = R.targetAllocations(cScores, amount, maxWeightBp, scoreAmplifierBp);

        assertEq(allocations.length, 2, "Should return same number of allocations as scores");

        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            totalAllocation += allocations[i];
        }

        assertEq(totalAllocation, amount, "Total allocations should equal input amount");
        assertTrue(allocations[0] > allocations[1], "Higher score should get higher allocation");
    }

    function testTargetLiquidityUsdRatioBp() public {
        uint256 tvlUsd = 1000e18; // 1000 USD
        uint16 minRatioBp = 500; // 5%
        uint16 tvlFactorBp = 300; // 3%
        uint16 tvlExponentBp = 300; // 0.3%

        uint256 ratio = R.targetLiquidityUsdRatioBp(tvlUsd, minRatioBp, tvlFactorBp, tvlExponentBp);

        assertTrue(ratio >= minRatioBp, "Ratio should be at least min ratio");
        assertTrue(ratio <= M.BPS, "Ratio should not exceed 100%");
    }

    function testTargetLiquidityUsd() public {
        uint256 tvlUsd = 1000e18; // 1000 USD
        uint16 minRatioBp = 500; // 5%
        uint16 tvlFactorBp = 300; // 3%
        uint16 tvlExponentBp = 300; // 0.3%

        uint256 targetLiquidity = R.targetLiquidityUsd(tvlUsd, minRatioBp, tvlFactorBp, tvlExponentBp);

        assertTrue(targetLiquidity >= tvlUsd.bpDown(minRatioBp), "Target liquidity should be at least min ratio of TVL");
        assertTrue(targetLiquidity <= tvlUsd, "Target liquidity should not exceed TVL");
    }

    function testCalculateSlippage() public {
        uint16 minSlippageBp = 10; // 0.1%
        uint16 maxSlippageBp = 500; // 5%
        uint16 amplificationBp = 5000; // 50% (linear)

        // Test positive ratio diff (improves ratio)
        int16 positiveRatioDiffBp = 1000; // 10% improvement
        uint256 slippage = R.calculateSlippage(positiveRatioDiffBp, minSlippageBp, maxSlippageBp, amplificationBp);
        assertTrue(slippage >= minSlippageBp, "Positive ratio diff should give good slippage");

        // Test negative ratio diff (worsens ratio)
        int16 negativeRatioDiffBp = -1000; // 10% worsening
        slippage = R.calculateSlippage(negativeRatioDiffBp, minSlippageBp, maxSlippageBp, amplificationBp);
        assertTrue(slippage > minSlippageBp, "Negative ratio diff should increase slippage");
        assertTrue(slippage <= maxSlippageBp, "Slippage should not exceed max");

        // Test maximum negative ratio diff
        int16 maxNegativeRatioDiffBp = -int16(M.BPS); // 100% worsening
        slippage = R.calculateSlippage(maxNegativeRatioDiffBp, minSlippageBp, maxSlippageBp, amplificationBp);
        assertTrue(slippage <= maxSlippageBp, "Maximum negative ratio diff should not exceed max slippage");
    }

    function testCalculateSlippageCurves() public {
        uint16 minSlippageBp = 10; // 0.1%
        uint16 maxSlippageBp = 500; // 5%
        int16 ratioDiffBp = -1000; // 10% worsening

        // Test concave curve (low amplification)
        uint256 concaveSlippage = R.calculateSlippage(ratioDiffBp, minSlippageBp, maxSlippageBp, 1000);

        // Test linear curve (medium amplification)
        uint256 linearSlippage = R.calculateSlippage(ratioDiffBp, minSlippageBp, maxSlippageBp, 5000);

        // Test convex curve (high amplification)
        uint256 convexSlippage = R.calculateSlippage(ratioDiffBp, minSlippageBp, maxSlippageBp, 9000);

        assertTrue(concaveSlippage >= minSlippageBp, "Concave slippage should be at least min");
        assertTrue(linearSlippage >= minSlippageBp, "Linear slippage should be at least min");
        assertTrue(convexSlippage >= minSlippageBp, "Convex slippage should be at least min");

        assertTrue(concaveSlippage <= maxSlippageBp, "Concave slippage should not exceed max");
        assertTrue(linearSlippage <= maxSlippageBp, "Linear slippage should not exceed max");
        assertTrue(convexSlippage <= maxSlippageBp, "Convex slippage should not exceed max");
    }

    // --- ACCESS CONTROL TESTS ---

    function testOnlyAdminCanSetRiskModel() public {
        RiskModel memory newModel = riskFacet.defaultRiskModel();

        vm.expectRevert();
        vm.prank(user);
        riskFacet.setRiskModel(newModel);
    }

    function testOnlyAdminCanSetWeightModel() public {
        WeightModel memory newModel = riskFacet.defaultWeightModel();

        vm.expectRevert();
        vm.prank(user);
        riskFacet.setWeightModel(newModel);
    }

    function testOnlyManagerCanSetPoolCScore() public {
        bytes32 poolId = keccak256("test-pool");

        vm.expectRevert();
        vm.prank(user);
        riskFacet.setPoolCScore(poolId, 8000);
    }

    // --- ERROR HANDLING TESTS ---

    function testCScoreWithInvalidScore() public {
        uint16[] memory invalidScores = new uint16[](1);
        invalidScores[0] = 15000; // > MAX_SCORE

        vm.expectRevert();
        R.cScore(invalidScores);
    }

    function testTargetWeightsWithInvalidParameters() public {
        uint16[] memory cScores = new uint16[](2);
        cScores[0] = 8000;
        cScores[1] = 6000;

        // Test with max weight > total weight
        vm.expectRevert();
        R.targetWeights(cScores, 6000, 5000, 1e4); // maxWeight > totalWeight

        // Test with total weight > MAX_WEIGHT
        vm.expectRevert();
        R.targetWeights(cScores, 5000, 15000, 1e4); // totalWeight > MAX_WEIGHT
    }

    // --- FUZZ TESTS ---

    function testFuzzCScore(uint16[] memory scores) public {
        vm.assume(scores.length <= 10); // Reasonable array size

        // Ensure all scores are valid
        for (uint256 i = 0; i < scores.length; i++) {
            vm.assume(scores[i] <= MAX_SCORE);
        }

        uint16 result = R.cScore(scores);
        assertTrue(result <= MAX_SCORE, "Composite score should not exceed max score");

        // If any score is zero, result should be zero
        for (uint256 i = 0; i < scores.length; i++) {
            if (scores[i] == 0) {
                assertEq(result, 0, "Zero score should make composite zero");
                return;
            }
        }
    }

    function testFuzzTargetLiquidityRatio(uint256 tvlUsd, uint16 minRatioBp) public {
        vm.assume(tvlUsd > 0 && tvlUsd <= 1e30); // Reasonable TVL range
        vm.assume(minRatioBp <= M.BPS); // Valid ratio

        uint16 tvlFactorBp = 300; // 3%
        uint16 tvlExponentBp = 300; // 0.3%

        uint256 ratio = R.targetLiquidityUsdRatioBp(tvlUsd, minRatioBp, tvlFactorBp, tvlExponentBp);

        assertTrue(ratio >= minRatioBp, "Ratio should be at least min ratio");
        assertTrue(ratio <= M.BPS, "Ratio should not exceed 100%");
    }
}
