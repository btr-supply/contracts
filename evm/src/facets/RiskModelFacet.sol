// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {RiskModel, WeightModel, LiquidityModel, SlippageModel} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibRisk as R} from "@libraries/LibRisk.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Risk Model Facet - Risk management and parameters
 * @copyright 2025
 * @notice Manages risk parameters, weight models, and liquidity constraints
 * @dev Controls risk management parameters for the protocol
- Weight models, slippage models, liquidity models
- Used for vault risk assessment and parameter validation

 * @author BTR Team
 */

contract RiskModelFacet is PermissionedFacet {
    // --- INITIALIZATION ---
    function initializeRiskModel() external onlyAdmin {
        R.initialize(S.risk());
    }
    // --- RISK MODEL CONFIGURATION ---

    function setRiskModel(RiskModel memory _model) external onlyAdmin {
        R.setModel(S.risk(), _model);
    }

    function riskModel() external view returns (RiskModel memory) {
        return R.model(S.risk());
    }

    // --- WEIGHT MODEL CONFIGURATION ---

    function setWeightModel(WeightModel memory _weight) external onlyAdmin {
        R.setWeightModel(S.risk(), _weight);
    }

    function weightModel() external view returns (WeightModel memory) {
        return R.weightModel(S.risk());
    }

    // --- LIQUIDITY MODEL CONFIGURATION ---

    function setLiquidityModel(LiquidityModel memory _liquidity) external onlyAdmin {
        R.setLiquidityModel(S.risk(), _liquidity);
    }

    function liquidityModel() external view returns (LiquidityModel memory) {
        return R.liquidityModel(S.risk());
    }

    // --- SLIPPAGE MODEL CONFIGURATION ---

    function setSlippageModel(SlippageModel memory _slippage) external onlyAdmin {
        R.setSlippageModel(S.risk(), _slippage);
    }

    function slippageModel() external view returns (SlippageModel memory) {
        return R.slippageModel(S.risk());
    }

    // --- POOL SCORING ---

    function setPoolCScore(bytes32 _poolId, uint16 _cScore) external onlyManager {
        R.setPoolCScore(S.reg(), _poolId, _cScore);
    }

    // --- VALIDATION ---

    function validateRiskModel(RiskModel memory _model) external pure {
        R.validateModel(_model);
    }

    function validateWeightModel(WeightModel memory _weight) external pure {
        R.validateWeightModel(_weight);
    }

    function validateLiquidityModel(LiquidityModel memory _liquidity) external pure {
        R.validateLiquidityModel(_liquidity);
    }

    function validateSlippageModel(SlippageModel memory _slippage) external pure {
        R.validateSlippageModel(_slippage);
    }

    // --- DEFAULTS ---

    function defaultRiskModel() external pure returns (RiskModel memory) {
        return R.defaultModel();
    }

    function defaultWeightModel() external pure returns (WeightModel memory) {
        return R.defaultWeightModel();
    }

    function defaultLiquidityModel() external pure returns (LiquidityModel memory) {
        return R.defaultLiquidityModel();
    }

    function defaultSlippageModel() external pure returns (SlippageModel memory) {
        return R.defaultSlippageModel();
    }
}
