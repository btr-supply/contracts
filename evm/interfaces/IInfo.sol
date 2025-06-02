// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Fees, RiskModel, WeightModel, LiquidityModel, AccountStatus} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInfo {
    // Protocol info
    function version() external view returns (uint8);
    // Treasury
    function hasCustomFees(address _user, uint32 _vaultId) external view returns (bool);
    function customFees(address _user, uint32 _vaultId) external view returns (Fees memory);
    // Management
    function accountStatus(address _account) external view returns (AccountStatus);
    function isWhitelisted(address _account) external view returns (bool);
    function isBlacklisted(address _account) external view returns (bool);
    function isSwapCallerRestricted(address _caller) external view returns (bool);
    function isSwapRouterRestricted(address _router) external view returns (bool);
    function isSwapInputRestricted(address _input) external view returns (bool);
    function isSwapOutputRestricted(address _output) external view returns (bool);
    function isBridgeInputRestricted(address _input) external view returns (bool);
    function isBridgeOutputRestricted(address _output) external view returns (bool);
    function isBridgeRouterRestricted(address _router) external view returns (bool);
    function isApproveMax() external view returns (bool);
    function isAutoRevoke() external view returns (bool);

    // Metrics
    function almTvlUsd(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceUsd0, uint256 _balanceUsd1);
    function almTvlEth(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceEth0, uint256 _balanceEth1);
    function almTvlBtc(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceBtc0, uint256 _balanceBtc1);
    function totalAlmTvlUsd() external view returns (uint256);
    function totalAlmTvlEth() external view returns (uint256);
    function totalAlmTvlBtc() external view returns (uint256);

    // Fee info
    function almPendingFees(uint32 _vid, IERC20 _token) external view returns (uint256);
    function almAccruedFees(uint32 _vid, IERC20 _token) external view returns (uint256);
    function totalAlmPendingFees(IERC20 _token) external view returns (uint256);
    function totalAlmAccruedFees(IERC20 _token) external view returns (uint256);

    // Risk model info
    function riskModel() external view returns (RiskModel memory);
    function weightModel() external view returns (WeightModel memory);
    function liquidityModel() external view returns (LiquidityModel memory);
    function poolCScore(bytes32 _poolId) external view returns (uint16);
    function almCScores(uint32 _vid) external view returns (uint16[] memory);
    function targetAlmLiquidityUsd(uint32 _vid) external view returns (uint256);
    function targetAlmLiquidityRatioBp(uint32 _vid) external view returns (uint256);
    function targetAlmWeightsAndLiquidity(uint32 _vid)
        external
        view
        returns (uint256[] memory weights, uint256 targetLiquidityRatioBp);
    function targetProtocolLiquidityUsd() external view returns (uint256);
}
