// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {RiskModel, WeightModel, LiquidityModel, SlippageModel} from "@/BTRTypes.sol";

interface IRiskModel {
    function initializeRiskModel() external;
    function setRiskModel(RiskModel memory _model) external;
    function riskModel() external view returns (RiskModel memory);
    function setWeightModel(WeightModel memory _weight) external;
    function weightModel() external view returns (WeightModel memory);
    function setLiquidityModel(LiquidityModel memory _liquidity) external;
    function liquidityModel() external view returns (LiquidityModel memory);
    function setSlippageModel(SlippageModel memory _slippage) external;
    function slippageModel() external view returns (SlippageModel memory);
    function setPoolCScore(bytes32 _poolId, uint16 _cScore) external;
    function validateRiskModel(RiskModel memory _model) external pure;
    function validateWeightModel(WeightModel memory _weight) external pure;
    function validateLiquidityModel(LiquidityModel memory _liquidity) external pure;
    function validateSlippageModel(SlippageModel memory _slippage) external pure;
    function defaultRiskModel() external pure returns (RiskModel memory);
    function defaultWeightModel() external pure returns (WeightModel memory);
    function defaultLiquidityModel() external pure returns (LiquidityModel memory);
    function defaultSlippageModel() external pure returns (SlippageModel memory);
}
