// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    ALMVault,
    Registry,
    LiquidityModel,
    WeightModel,
    SlippageModel,
    RiskModel,
    Oracles,
    PoolInfo,
    Range,
    ErrorType
} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibCast as C} from "./LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibMetrics as MT} from "@libraries/LibMetrics.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Risk Library - Risk management logic
 * @copyright 2025
 * @notice Contains internal functions for risk assessment, weight calculation, and parameter validation
 * @dev Helper library for RiskModelFacet and risk-aware components
 * @author BTR Team
 */

library LibRisk {
    using M for uint256;
    using C for uint256;
    using MT for ALMVault;

    uint16 internal constant MAX_SCORE = uint16(M.BPS); // 100% in BPS
    uint16 internal constant MAX_WEIGHT = uint16(M.BPS); // 100% in BPS
    uint256 internal constant MAX_WEIGHT_WAD = uint256(M.WAD); // 100% in WAD

    // --- DEFAULT MODELS ---

    function defaultWeightModel() internal pure returns (WeightModel memory) {
        return WeightModel({
            defaultCScore: MAX_SCORE / 2, // Default pool cScore is 50%
            scoreAmplifierBp: 1.5e4, // Medium low score penalty
            minMaxBp: 0.25e4, // Best vault pool minimum max weight == 25%
            maxBp: MAX_WEIGHT, // Single pool can be 100% of a vault's exposure (if 1 pool per vault), no hard cap
            diversificationFactorBp: 0.3e4, // Good diversification, higher exponent increase weight/exposure concentration
            __gap: [bytes32(0), bytes32(0)]
        });
    }

    function defaultLiquidityModel() internal pure returns (LiquidityModel memory) {
        return LiquidityModel({
            minRatioBp: 0.05e4, // 5% minimum vault liquidity ratio
            tvlExponentBp: 0.3e4, // 30% liquidity ratio TVL exponential decay - same as tvlFactorBp
            tvlFactorBp: 0.3e4, // 30% liquidity ratio TVL linear decay
            lowOffsetBp: 0.5e4, // Low liquidity trigger is 50% of below liquidity target ratio
            highOffsetBp: 0.5e4, // High liquidity trigger is 50% of above liquidity target ratio
            __gap: [bytes32(0), bytes32(0)]
        });
    }

    function defaultSlippageModel() internal pure returns (SlippageModel memory) {
        return SlippageModel({
            minSlippageBp: 1, // 0.01% minimum slippage
            maxSlippageBp: 200, // 2% maximum slippage
            amplificationBp: 3500, // 0.35 (concave curve, more aggressive penalty for negative ratioDiff0)
            __gap: [bytes32(0), bytes32(0)]
        });
    }

    function defaultModel() internal pure returns (RiskModel memory) {
        return RiskModel({
            weight: defaultWeightModel(),
            liquidity: defaultLiquidityModel(),
            slippage: defaultSlippageModel(),
            __gap: [bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)]
        });
    }

    // --- VALIDATION ---

    function validateWeightModel(WeightModel memory _model) internal pure {
        if (
            _model.scoreAmplifierBp < 0.75e4 || _model.scoreAmplifierBp > 2.5e4 || _model.maxBp > MAX_WEIGHT
                || _model.maxBp < 0.1e4 || _model.minMaxBp > MAX_WEIGHT || _model.diversificationFactorBp < 0.05e4
                || _model.diversificationFactorBp > 2e4
        ) {
            revert Errors.UnexpectedInput();
        }
    }

    function validateLiquidityModel(LiquidityModel memory _liquidity) internal pure {
        if (
            _liquidity.minRatioBp > M.BPS || _liquidity.tvlExponentBp < 0.05e4 || _liquidity.tvlExponentBp > 2e4
                || _liquidity.tvlFactorBp < 0.05e4 || _liquidity.tvlFactorBp > 2e4 || _liquidity.lowOffsetBp < 0.05e4
                || _liquidity.highOffsetBp < 0.05e4
        ) {
            revert Errors.UnexpectedInput();
        }
    }

    function validateSlippageModel(SlippageModel memory _slippage) internal pure {
        if (
            _slippage.minSlippageBp >= _slippage.maxSlippageBp || _slippage.maxSlippageBp > 0.1e4
                || _slippage.amplificationBp > M.BPS
        ) {
            revert Errors.UnexpectedInput();
        }
    }

    function validateModel(RiskModel memory _model) internal pure {
        validateWeightModel(_model.weight);
        validateLiquidityModel(_model.liquidity);
        validateSlippageModel(_model.slippage);
    }

    // --- INITIALIZATION ---

    function initialize(RiskModel storage _risk) internal {
        setModel(_risk, defaultModel());
    }

    // --- CONFIGURATION ---

    function model(RiskModel storage _risk) internal view returns (RiskModel memory) {
        return
            RiskModel({weight: _risk.weight, liquidity: _risk.liquidity, slippage: _risk.slippage, __gap: _risk.__gap});
    }

    function weightModel(RiskModel storage _risk) internal view returns (WeightModel memory) {
        return _risk.weight;
    }

    function liquidityModel(RiskModel storage _risk) internal view returns (LiquidityModel memory) {
        return _risk.liquidity;
    }

    function slippageModel(RiskModel storage _risk) internal view returns (SlippageModel memory) {
        return _risk.slippage;
    }

    function setModel(RiskModel storage _risk, RiskModel memory _model) internal {
        validateModel(_model);
        RiskModel memory oldModel = _risk;
        _risk.weight = _model.weight;
        _risk.liquidity = _model.liquidity;
        _risk.slippage = _model.slippage;
        emit Events.RiskModelUpdated(oldModel, _model);
    }

    function setWeightModel(RiskModel storage _risk, WeightModel memory _weight) internal {
        validateWeightModel(_weight);
        WeightModel memory oldWeight = _risk.weight;
        _risk.weight = _weight;
        emit Events.WeightModelUpdated(oldWeight, _weight);
    }

    function setLiquidityModel(RiskModel storage _risk, LiquidityModel memory _liquidity) internal {
        validateLiquidityModel(_liquidity);
        LiquidityModel memory oldLiquidity = _risk.liquidity;
        _risk.liquidity = _liquidity;
        emit Events.LiquidityModelUpdated(oldLiquidity, _liquidity);
    }

    function setSlippageModel(RiskModel storage _risk, SlippageModel memory _slippage) internal {
        validateSlippageModel(_slippage);
        SlippageModel memory oldSlippage = _risk.slippage;
        _risk.slippage = _slippage;
        emit Events.SlippageModelUpdated(oldSlippage, _slippage);
    }

    function setPoolCScore(Registry storage _reg, bytes32 _pid, uint16 _cScore) internal {
        PoolInfo storage pool = _reg.poolInfo[_pid];
        if (pool.id == bytes32(0)) revert Errors.NotFound(ErrorType.POOL);
        if (_cScore > MAX_SCORE) revert Errors.Exceeds(_cScore, MAX_SCORE);

        uint16 oldScore = pool.cScore;
        pool.cScore = _cScore;
        emit Events.PoolCScoreUpdated(_pid, oldScore, _cScore);
    }

    // --- COMPUTATIONS ---

    function componentMaxWeightBp(uint256 _components, uint16 _minMaxBp, uint16 _diversificationFactorBp, uint16 _maxBp)
        internal
        pure
        returns (uint256)
    {
        uint256 calculatedMax = _minMaxBp
            + uint256(M.expWad(-int256(_components) * int256(uint256(_diversificationFactorBp).toWad()))).toBp();
        return calculatedMax < _maxBp ? calculatedMax : _maxBp;
    }

    function cScore(uint16[] memory _scores) internal pure returns (uint16) {
        uint256 n = _scores.length;
        if (n == 0) return 0;
        if (n == 1) return _scores[0];

        uint256 prodWad = M.WAD;
        unchecked {
            for (uint256 i; i < n; i++) {
                uint256 s = _scores[i];
                if (s == 0) return 0;
                if (s > MAX_SCORE) revert Errors.Exceeds(s, MAX_SCORE);
                prodWad = prodWad.mulWad(uint256(s).toWad());
            }
        }

        int256 logProd = M.lnWad(int256(prodWad));
        int256 geomWad = M.expWad(logProd / int256(n));
        return uint16(uint256(geomWad).mulDivDown(MAX_SCORE, M.WAD));
    }

    function _capWeights(uint256[] memory _weights, uint256 _uncappedTotal, uint256 _maxWeight, uint256 _totalWeight)
        private
        pure
        returns (uint256)
    {
        uint256 n = _weights.length;
        if (n == 0 || _uncappedTotal == 0) return 0;

        uint256 cappedTotal = _uncappedTotal;
        unchecked {
            for (uint256 it; it < 10; it++) {
                uint256 excess;
                // Cap and collect excess
                for (uint256 i; i < n; i++) {
                    uint256 share = _weights[i].mulDivDown(_totalWeight, cappedTotal);
                    if (share > _maxWeight) {
                        uint256 cap = _maxWeight.mulDivDown(cappedTotal, _totalWeight);
                        excess += _weights[i] - cap;
                        _weights[i] = cap;
                    }
                }
                if (excess == 0) break;
                cappedTotal -= excess;

                // Calculate pool for redistribution
                uint256 pool;
                for (uint256 i; i < n; i++) {
                    if (_weights[i].mulDivDown(_totalWeight, cappedTotal) < _maxWeight) {
                        pool += _weights[i];
                    }
                }
                if (pool == 0) continue;

                // Redistribute excess
                uint256 dist;
                for (uint256 i; i < n; i++) {
                    if (_weights[i].mulDivDown(_totalWeight, cappedTotal) < _maxWeight) {
                        uint256 add = excess.mulDivDown(_weights[i], pool);
                        _weights[i] += add;
                        dist += add;
                    }
                }
                cappedTotal += dist;
                if (cappedTotal == 0) break;
            }
        }
        return cappedTotal;
    }

    function targetWeights(
        uint16[] memory _cScores,
        uint16 _maxWeightBp,
        uint16 _totalWeightBp,
        uint16 _scoreAmplifierBp
    ) internal pure returns (uint256[] memory) {
        uint256 n = _cScores.length;
        if (n == 0) return new uint256[](0);
        if (_maxWeightBp == 0 || _maxWeightBp > _totalWeightBp || _totalWeightBp > MAX_WEIGHT) {
            revert Errors.Exceeds(_totalWeightBp, MAX_WEIGHT);
        }

        // Calculate raw WAD weights
        uint256[] memory uncappedWeightWad = new uint256[](n);
        uint256 totalWad;
        for (uint256 i; i < n; i++) {
            uncappedWeightWad[i] = _cScores[i] == 0
                ? 0
                : uint256(M.powWad(int256(uint256(_cScores[i]).toWad()), int256(uint256(_scoreAmplifierBp).toWad())));
            totalWad += uncappedWeightWad[i];
        }
        if (totalWad == 0) return new uint256[](n);

        // Cap weights
        uint256 capTotalWad =
            _capWeights(uncappedWeightWad, totalWad, uint256(_maxWeightBp).toWad(), uint256(_totalWeightBp).toWad());
        if (capTotalWad == 0) return new uint256[](n);

        // Normalize to BPS with dust adjustment
        uint256[] memory weightsBp = new uint256[](n);
        uint256 sumBp;
        uint256 maxIdx;
        for (uint256 i; i < n; i++) {
            uint256 weightBp = uncappedWeightWad[i].mulDivDown(_totalWeightBp, capTotalWad);
            weightsBp[i] = weightBp;
            sumBp += weightBp;
            if (weightBp > weightsBp[maxIdx]) maxIdx = i;
        }

        // Dust adjustment
        if (sumBp < _totalWeightBp) {
            weightsBp[maxIdx] += _totalWeightBp - sumBp;
        } else if (sumBp > _totalWeightBp) {
            uint256 over = sumBp - _totalWeightBp;
            if (weightsBp[maxIdx] >= over) weightsBp[maxIdx] -= over;
        }
        return weightsBp;
    }

    function targetAllocations(uint16[] memory _cScores, uint256 _amount, uint16 _maxWeightBp, uint16 _scoreAmplifierBp)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory weights = targetWeights(_cScores, _maxWeightBp, MAX_WEIGHT, _scoreAmplifierBp);
        uint256 n = weights.length;
        if (n == 0) return new uint256[](0);

        uint256[] memory alloc = new uint256[](n);
        uint256 sumAllocated;
        uint256 maxIdxAlloc;
        unchecked {
            for (uint256 i; i < n; i++) {
                alloc[i] = _amount.bpDown(weights[i]);
                sumAllocated += alloc[i];
                if (alloc[i] > alloc[maxIdxAlloc]) maxIdxAlloc = i;
            }
        }

        uint256 remainder = _amount - sumAllocated;
        if (remainder != 0) alloc[maxIdxAlloc] += remainder;
        return alloc;
    }

    function almCScores(ALMVault storage _vault, Registry storage _reg) internal view returns (uint16[] memory) {
        bytes32[] storage rangeIds = _vault.ranges;
        uint16[] memory cScores = new uint16[](rangeIds.length);
        unchecked {
            for (uint256 i; i < rangeIds.length; i++) {
                cScores[i] = _reg.poolInfo[_reg.ranges[rangeIds[i]].poolId].cScore;
            }
        }
        return cScores;
    }

    function targetAlmWeights(ALMVault storage _vault, Registry storage _reg, RiskModel storage _risk)
        internal
        view
        returns (uint256[] memory)
    {
        return targetWeights(almCScores(_vault, _reg), _risk.weight.maxBp, MAX_WEIGHT, _risk.weight.scoreAmplifierBp);
    }

    function targetAlmAllocations(ALMVault storage _vault, Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256[] memory)
    {
        (,, uint256 balanceUsd0, uint256 balanceUsd1) = MT.almTvlUsd(_vault, _reg, _ora);
        return targetAllocations(almCScores(_vault, _reg), balanceUsd0 + balanceUsd1, MAX_WEIGHT, uint16(M.WAD.toBp()));
    }

    // --- LIQUIDITY CALCULATIONS ---

    function targetLiquidityUsdRatioBp(uint256 _tvlUsd, uint16 _minRatioBp, uint16 _tvlFactorBp, uint16 _tvlExponentBp)
        internal
        pure
        returns (uint256)
    {
        if (_minRatioBp > M.BPS) revert Errors.Exceeds(_minRatioBp, M.BPS);
        if (_minRatioBp == M.BPS) return M.BPS;

        uint256 weightedTvlWad = M.WAD + M.mulWad(_tvlUsd, uint256(_tvlFactorBp).toWad());
        weightedTvlWad = uint256(M.powWad(int256(weightedTvlWad), -int256(uint256(_tvlExponentBp).toWad())));
        return _minRatioBp + (M.BPS - _minRatioBp) * weightedTvlWad.toBp();
    }

    function targetLiquidityUsd(uint256 _tvlUsd, uint16 _minRatioBp, uint16 _tvlFactorBp, uint16 _tvlExponentBp)
        internal
        pure
        returns (uint256)
    {
        return _tvlUsd.mulDivDown(targetLiquidityUsdRatioBp(_tvlUsd, _minRatioBp, _tvlFactorBp, _tvlExponentBp), M.BPS);
    }

    function targetAlmLiquidityUsd(
        ALMVault storage _vault,
        Registry storage _reg,
        RiskModel storage _risk,
        Oracles storage _ora
    ) internal view returns (uint256) {
        (,, uint256 balanceUsd0, uint256 balanceUsd1) = MT.almTvlUsd(_vault, _reg, _ora);
        LiquidityModel storage liquidity = _risk.liquidity;
        return targetLiquidityUsd(
            balanceUsd0 + balanceUsd1, liquidity.minRatioBp, liquidity.tvlFactorBp, liquidity.tvlExponentBp
        );
    }

    function targetAlmLiquidityRatioBp(
        ALMVault storage _vault,
        Registry storage _reg,
        RiskModel storage _risk,
        Oracles storage _ora
    ) internal view returns (uint256) {
        (,, uint256 balanceUsd0, uint256 balanceUsd1) = MT.almTvlUsd(_vault, _reg, _ora);
        LiquidityModel storage liquidity = _risk.liquidity;
        return targetLiquidityUsdRatioBp(
            balanceUsd0 + balanceUsd1, liquidity.minRatioBp, liquidity.tvlFactorBp, liquidity.tvlExponentBp
        );
    }

    function targetAlmWeightsAndLiquidity(
        ALMVault storage _vault,
        Registry storage _reg,
        RiskModel storage _risk,
        Oracles storage _ora
    ) internal view returns (uint256[] memory weights, uint256 targetLiquidityRatioBp) {
        weights = targetAlmWeights(_vault, _reg, _risk);
        targetLiquidityRatioBp = targetAlmLiquidityRatioBp(_vault, _reg, _risk, _ora);
    }

    function targetProtocolLiquidityUsd(Registry storage _reg, RiskModel storage _risk, Oracles storage _ora)
        internal
        view
        returns (uint256)
    {
        uint256 totalTvlUsd = MT.totalAlmTvlUsd(_reg, _ora);
        LiquidityModel storage liquidity = _risk.liquidity;
        return targetLiquidityUsd(totalTvlUsd, liquidity.minRatioBp, liquidity.tvlFactorBp, liquidity.tvlExponentBp);
    }

    // --- SLIPPAGE CALCULATIONS ---

    function calculateSlippage(
        int16 _ratioDiff0Bp,
        uint16 _minSlippageBp,
        uint16 _maxSlippageBp,
        uint16 _amplificationBp
    ) internal pure returns (uint256 slippageBp) {
        // Normalize ratio difference to [0, WAD] range
        uint256 normalizedRatio = uint256(int256(_ratioDiff0Bp) + int256(M.BPS)).mulDivDown(M.WAD, 2 * M.BPS);

        // Calculate transformation exponent
        uint256 amplificationDiff = _amplificationBp >= 5000 ? _amplificationBp - 5000 : 5000 - _amplificationBp;
        int256 exponentWad = M.expWad(int256(amplificationDiff.mulDivDown(M.WAD, 2500)));

        // Apply transformation based on amplification
        uint256 transformed = _amplificationBp <= 5000
            ? M.WAD - uint256(M.powWad(int256(M.WAD - normalizedRatio), exponentWad))
            : uint256(M.powWad(int256(normalizedRatio), exponentWad));

        if (transformed > M.WAD) transformed = M.WAD;

        // Map to slippage range
        uint256 slippageRange =
            _maxSlippageBp >= _minSlippageBp ? _maxSlippageBp - _minSlippageBp : _minSlippageBp - _maxSlippageBp;

        slippageBp = _maxSlippageBp >= _minSlippageBp
            ? _maxSlippageBp - slippageRange.mulDivDown(transformed, M.WAD)
            : _maxSlippageBp + slippageRange.mulDivDown(transformed, M.WAD);

        // Bound result
        uint256 minBound = _minSlippageBp < _maxSlippageBp ? _minSlippageBp : _maxSlippageBp;
        uint256 maxBound = _minSlippageBp > _maxSlippageBp ? _minSlippageBp : _maxSlippageBp;

        if (slippageBp < minBound) slippageBp = minBound;
        else if (slippageBp > maxBound) slippageBp = maxBound;
    }
}
