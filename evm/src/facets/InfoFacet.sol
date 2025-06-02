// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {
    Registry,
    ALMVault,
    Range,
    PoolInfo,
    FeeType,
    Fees,
    RiskModel,
    WeightModel,
    LiquidityModel,
    AccountStatus
} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibManagement as M} from "@libraries/LibManagement.sol";
import {LibMetrics as LM} from "@libraries/LibMetrics.sol";
import {LibRisk as R} from "@libraries/LibRisk.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Info Facet - General protocol information
 * @copyright 2025
 * @notice Provides general protocol-level information and statistics
 * @dev General information queries not specific to ALM
 * @author BTR Team
 */

contract InfoFacet {
    using U for uint32;
    using U for address;

    // --- PROTOCOL INFO ---

    function version() external view returns (uint8) {
        return M.version(S.core());
    }

    // --- TREASURY ---

    function hasCustomFees(address _user, uint32 /* _vaultId */ ) external view returns (bool) {
        return T.hasCustomFees(S.tres(), _user);
    }

    function customFees(address _user, uint32 /* _vaultId */ )
        external
        view
        returns (uint16 entry, uint16 exit, uint16 mgmt, uint16 perf, uint16 flash)
    {
        Fees memory fees = T.customFees(S.tres(), _user);
        return (fees.entry, fees.exit, fees.mgmt, fees.perf, fees.flash);
    }

    // --- MANAGEMENT ---

    function accountStatus(address _account) external view returns (AccountStatus) {
        return AC.accountStatus(S.rst(), _account);
    }

    function isWhitelisted(address _account) external view returns (bool) {
        return AC.isWhitelisted(S.rst(), _account);
    }

    function isBlacklisted(address _account) external view returns (bool) {
        return AC.isBlacklisted(S.rst(), _account);
    }

    function isSwapCallerRestricted(address _caller) external view returns (bool) {
        return M.isSwapCallerRestricted(S.rst(), _caller);
    }

    function isSwapRouterRestricted(address _router) external view returns (bool) {
        return M.isSwapRouterRestricted(S.rst(), _router);
    }

    function isSwapInputRestricted(address _input) external view returns (bool) {
        return M.isSwapInputRestricted(S.rst(), _input);
    }

    function isSwapOutputRestricted(address _output) external view returns (bool) {
        return M.isSwapOutputRestricted(S.rst(), _output);
    }

    function isBridgeInputRestricted(address _input) external view returns (bool) {
        return M.isBridgeInputRestricted(S.rst(), _input);
    }

    function isBridgeOutputRestricted(address _output) external view returns (bool) {
        return M.isBridgeOutputRestricted(S.rst(), _output);
    }

    function isBridgeRouterRestricted(address _router) external view returns (bool) {
        return M.isBridgeRouterRestricted(S.rst(), _router);
    }

    function isApproveMax() external view returns (bool) {
        return M.isApproveMax(S.rst());
    }

    function isAutoRevoke() external view returns (bool) {
        return M.isAutoRevoke(S.rst());
    }

    // --- METRICS ---

    function almTvlUsd(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceUsd0, uint256 _balanceUsd1)
    {
        return LM.almTvlUsd(_vid.vault(), S.reg(), S.ora());
    }

    function almTvlEth(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceEth0, uint256 _balanceEth1)
    {
        return LM.almTvlEth(_vid.vault(), S.reg(), S.ora());
    }

    function almTvlBtc(uint32 _vid)
        external
        view
        returns (uint256 _balance0, uint256 _balance1, uint256 _balanceBtc0, uint256 _balanceBtc1)
    {
        return LM.almTvlBtc(_vid.vault(), S.reg(), S.ora());
    }

    function totalAlmTvlUsd() external view returns (uint256) {
        return LM.totalAlmTvlUsd(S.reg(), S.ora());
    }

    function totalAlmTvlEth() external view returns (uint256) {
        return LM.totalAlmTvlEth(S.reg(), S.ora());
    }

    function totalAlmTvlBtc() external view returns (uint256) {
        return LM.totalAlmTvlBtc(S.reg(), S.ora());
    }

    // --- FEE INFO ---

    function almPendingFees(uint32 _vid, IERC20 _token) external view returns (uint256) {
        return T.almPendingFees(_vid.vault(), _token);
    }

    function almAccruedFees(uint32 _vid, IERC20 _token) external view returns (uint256) {
        return T.almAccruedFees(_vid.vault(), _token);
    }

    function totalAlmPendingFees(IERC20 _token) external view returns (uint256) {
        return T.totalAlmPendingFees(_token);
    }

    function totalAlmAccruedFees(IERC20 _token) external view returns (uint256) {
        return T.totalAlmAccruedFees(_token);
    }

    // --- RISK MODEL INFO ---

    function riskModel() external view returns (RiskModel memory) {
        return R.model(S.risk());
    }

    function weightModel() external view returns (WeightModel memory) {
        return R.weightModel(S.risk());
    }

    function liquidityModel() external view returns (LiquidityModel memory) {
        return R.liquidityModel(S.risk());
    }

    function poolCScore(bytes32 _poolId) external view returns (uint16) {
        return S.reg().poolInfo[_poolId].cScore;
    }

    function almCScores(uint32 _vid) external view returns (uint16[] memory) {
        return R.almCScores(_vid.vault(), S.reg());
    }

    function targetAlmLiquidityUsd(uint32 _vid) external view returns (uint256) {
        return R.targetAlmLiquidityUsd(_vid.vault(), S.reg(), S.risk(), S.ora());
    }

    function targetAlmLiquidityRatioBp(uint32 _vid) external view returns (uint256) {
        return R.targetAlmLiquidityRatioBp(_vid.vault(), S.reg(), S.risk(), S.ora());
    }

    function targetAlmWeightsAndLiquidity(uint32 _vid) external view returns (uint256[] memory, uint256) {
        return R.targetAlmWeightsAndLiquidity(_vid.vault(), S.reg(), S.risk(), S.ora());
    }

    function targetProtocolLiquidityUsd() external view returns (uint256) {
        return R.targetProtocolLiquidityUsd(S.reg(), S.risk(), S.ora());
    }
}
