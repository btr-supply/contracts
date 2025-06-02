// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {CoreStorage, Fees, ErrorType, ALMVault, Registry, Treasury, AccessControl, FeeType} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
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
 * @title Treasury Library - Treasury management logic
 * @copyright 2025
 * @notice Contains internal functions for managing treasury funds and distributions
 * @dev Helper library for TreasuryFacet
 * @author BTR Team
 */

library LibTreasury {
    using SafeERC20 for IERC20;
    using ALMB for ALMVault;
    using U for uint32;
    using M for uint256;

    uint16 internal constant MIN_FEE_BPS = 0;
    uint16 internal constant MAX_FEE_BPS = 5000;
    uint16 internal constant MAX_FLASH_FEE_BPS = 5000;
    uint16 internal constant MAX_PERF_FEE_BPS = 5000;
    uint16 internal constant MAX_ENTRY_FEE_BPS = 5000;
    uint16 internal constant MAX_EXIT_FEE_BPS = 5000;
    uint16 internal constant MAX_MGMT_FEE_BPS = 5000;

    // --- INITIALIZATION ---

    function initialize(Treasury storage _tres) internal {}

    function setCollector(Treasury storage _tres, AccessControl storage _ac, address _treasury) internal {
        if (_treasury == address(0)) revert Errors.ZeroAddress();
        if (_treasury == _tres.collector) revert Errors.AlreadyExists(ErrorType.ADDRESS);
        AC.safeGrantRole(_ac, AC.TREASURY_ROLE, _treasury, _tres.collector);
        _tres.collector = _treasury;
        emit Events.TreasuryUpdated(_treasury);
    }

    function validateFees(Fees memory _fees) internal pure {
        if (_fees.entry > MAX_ENTRY_FEE_BPS) revert Errors.Exceeds(_fees.entry, MAX_ENTRY_FEE_BPS);
        if (_fees.exit > MAX_EXIT_FEE_BPS) revert Errors.Exceeds(_fees.exit, MAX_EXIT_FEE_BPS);
        if (_fees.mgmt > MAX_MGMT_FEE_BPS) revert Errors.Exceeds(_fees.mgmt, MAX_MGMT_FEE_BPS);
        if (_fees.perf > MAX_PERF_FEE_BPS) revert Errors.Exceeds(_fees.perf, MAX_PERF_FEE_BPS);
        if (_fees.flash > MAX_FLASH_FEE_BPS) revert Errors.Exceeds(_fees.flash, MAX_FLASH_FEE_BPS);
    }

    function setDefaultFees(Fees memory _fees) internal {
        setAlmVaultFees(uint32(0).vault(), _fees);
    }

    function defaultFees() internal view returns (Fees memory) {
        return almVaultFees(uint32(0).vault());
    }

    function setAlmVaultFees(ALMVault storage _vault, Fees memory _fees) internal {
        validateFees(_fees);
        _fees.updatedAt = uint64(block.timestamp);
        _vault.fees = _fees;
        emit Events.FeesUpdated(_vault.id, _fees.entry, _fees.exit, _fees.mgmt, _fees.perf, _fees.flash);
    }

    function almVaultFees(ALMVault storage _vault) internal view returns (Fees memory) {
        return _vault.fees;
    }

    function almPendingFees(ALMVault storage _vault, IERC20 _token) internal view returns (uint256) {
        return _vault.pendingFees[address(_token)];
    }

    function almAccruedFees(ALMVault storage _vault, IERC20 _token) internal view returns (uint256) {
        return _vault.accruedFees[address(_token)];
    }

    function totalAlmPendingFees(IERC20 _token) internal view returns (uint256) {
        return almPendingFees(uint32(0).vault(), _token);
    }

    function totalAlmAccruedFees(IERC20 _token) internal view returns (uint256) {
        return almAccruedFees(uint32(0).vault(), _token);
    }

    function previewAlmPerfFees(ALMVault storage _vault, uint256 _lpFee0, uint256 _lpFee1)
        internal
        view
        returns (uint256 perfFee0, uint256 perfFee1)
    {
        return (_lpFee0.bpUp(_vault.fees.perf), _lpFee1.bpUp(_vault.fees.perf));
    }

    function previewAlmMgmtFees(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256 fee0, uint256 fee1)
    {
        if (_vault.fees.mgmt == 0) return (0, 0); // Zero fees
        uint256 lastAccruedAt = _vault.timePoints.accruedAt;
        if (block.timestamp <= lastAccruedAt) return (0, 0); // Too early to accrue
        uint256 elapsed = block.timestamp - lastAccruedAt;
        (uint256 balance0, uint256 balance1) = _vault.lpBalances(_reg);
        uint256 durationBp = elapsed.mulDivUp(M.PREC_BPS, M.SEC_PER_YEAR);
        uint256 scaledRate = uint256(_vault.fees.mgmt).mulDivUp(durationBp, M.BPS);
        fee0 = balance0.mulDivUp(scaledRate, M.PREC_BPS);
        fee1 = balance1.mulDivUp(scaledRate, M.PREC_BPS);
    }

    function accrueAlmFees(ALMVault storage _vault, Registry storage _reg, uint256 _lpFee0, uint256 _lpFee1)
        internal
        returns (uint256 fee0, uint256 fee1)
    {
        (uint256 perfFee0, uint256 perfFee1, uint256 mgmtFee0, uint256 mgmtFee1) =
            previewAlmFees(_vault, _reg, _lpFee0, _lpFee1);
        (fee0, fee1) = (perfFee0 + mgmtFee0, perfFee1 + mgmtFee1);
        _vault.pendingFees[address(_vault.token0)] += fee0;
        _vault.pendingFees[address(_vault.token1)] += fee1;
        _vault.accruedFees[address(_vault.token0)] += fee0;
        _vault.accruedFees[address(_vault.token1)] += fee1;
        _vault.timePoints.accruedAt = uint64(block.timestamp);
        emit Events.ALMFeesAccrued(
            _vault.id, address(_vault.token0), address(_vault.token1), perfFee0, perfFee1, mgmtFee0, mgmtFee1
        );
    }

    function previewAlmFees(ALMVault storage _vault, Registry storage _reg, uint256 _lpFee0, uint256 _lpFee1)
        internal
        view
        returns (uint256 perfFee0, uint256 perfFee1, uint256 mgmtFee0, uint256 mgmtFee1)
    {
        (perfFee0, perfFee1) = previewAlmPerfFees(_vault, _lpFee0, _lpFee1);
        (mgmtFee0, mgmtFee1) = previewAlmMgmtFees(_vault, _reg);
    }

    function previewTotalAlmFees(ALMVault storage _vault, Registry storage _reg, uint256 _lpFee0, uint256 _lpFee1)
        internal
        view
        returns (uint256 totalFee0, uint256 totalFee1)
    {
        (uint256 perfFee0, uint256 perfFee1, uint256 mgmtFee0, uint256 mgmtFee1) =
            previewAlmFees(_vault, _reg, _lpFee0, _lpFee1);
        (totalFee0, totalFee1) = (perfFee0 + mgmtFee0, perfFee1 + mgmtFee1);
    }

    function collectAlmFees(ALMVault storage _vault, Treasury storage _tres)
        internal
        returns (uint256 fee0, uint256 fee1)
    {
        (address t0, address t1) = (address(_vault.token0), address(_vault.token1));
        (fee0, fee1) = (_vault.pendingFees[t0], _vault.pendingFees[t1]);
        address _collector = _tres.collector;
        if (_collector == address(0)) revert Errors.ZeroAddress();
        if (fee0 + fee1 == 0) revert Errors.ZeroValue();
        (_vault.pendingFees[t0], _vault.pendingFees[t1]) = (0, 0); // Reset pending fees
        if (fee0 > 0) _vault.token0.safeTransfer(_collector, fee0);
        if (fee1 > 0) _vault.token1.safeTransfer(_collector, fee1);
        _vault.timePoints.collectedAt = uint64(block.timestamp);
        emit Events.ALMFeesCollected(_vault.id, t0, t1, fee0, fee1, _collector);
    }

    // --- CUSTOM USER FEES ---

    function hasCustomFees(Treasury storage _tres, address _user) internal view returns (bool) {
        return _tres.customFees[_user].updatedAt > 0;
    }

    function setCustomFees(Treasury storage _tres, address _user, Fees memory _fees) internal {
        if (_user == address(0)) revert Errors.ZeroAddress();
        validateFees(_fees);
        _fees.updatedAt = uint64(block.timestamp);
        _tres.customFees[_user] = _fees;
        emit Events.CustomFeesUpdated(_user, _fees.entry, _fees.exit, _fees.mgmt, _fees.perf, _fees.flash);
    }

    function customFees(Treasury storage _tres, address _user) internal view returns (Fees memory) {
        if (_user == address(0)) revert Errors.ZeroAddress();
        return _tres.customFees[_user];
    }

    function fees(Treasury storage _tres, address _user) internal view returns (Fees memory userFees) {
        userFees = customFees(_tres, _user);
        if (userFees.updatedAt == 0) {
            userFees = defaultFees();
        }
    }

    function almFees(Treasury storage _tres, address _user, ALMVault storage _vault)
        internal
        view
        returns (Fees memory userFees)
    {
        userFees = hasCustomFees(_tres, _user) ? customFees(_tres, _user) : almVaultFees(_vault);
    }

    // --- ALMVAULT EXTENSION FUNCTIONS ---

    function amountsToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount0,
        uint256 _amount1,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int256 rd0) {
        return ALMB.amountsToShares(_vault, _reg, S.tres(), _amount0, _amount1, _feeType, _user);
    }

    function sharesToAmounts(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _shares,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 net0, uint256 net1, uint256 fee0, uint256 fee1) {
        return ALMB.sharesToAmounts(_vault, _reg, S.tres(), _shares, _feeType, _user);
    }

    function sharesToAmount0(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _shares,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 amount0, uint256 fee0, uint256 fee1, int256 rd0) {
        return ALMB.sharesToAmount0(_vault, _reg, S.tres(), _shares, _feeType, _user);
    }

    function sharesToAmount1(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _shares,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 amount1, uint256 fee0, uint256 fee1, int256 rd0) {
        return ALMB.sharesToAmount1(_vault, _reg, S.tres(), _shares, _feeType, _user);
    }

    function amount0ToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount0,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int256 rd0) {
        return ALMB.amount0ToShares(_vault, _reg, S.tres(), _amount0, _feeType, _user);
    }

    function amount1ToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount1,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int256 rd0) {
        return ALMB.amount1ToShares(_vault, _reg, S.tres(), _amount1, _feeType, _user);
    }
}
