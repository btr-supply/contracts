// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {ALMVault, Registry, ErrorType, FeeType, MintProceeds, BurnProceeds} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
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
 * @title ALM User Library - ALM user state-changing operations
 * @copyright 2025
 * @notice Contains internal functions for ALM user operations including deposits, withdrawals, and previews with safety mechanisms
 * @dev Sub-facet for ALM user operations:
- Functions: Regular and safe variants of `deposit`, `mint`, `depositExact0`, `depositExact1`, `redeem`, `withdraw`, `withdrawExact0`, `withdrawExact1`, plus preview functions
- Includes error-handling mechanisms for safe operations with minimums/maximums
 * @author BTR Team
 */

library LibALMUser {
    using SafeERC20 for IERC20;
    using ALMB for ALMVault;
    using U for uint32;
    using T for ALMVault;
    using M for uint256;

    function previewDeposit(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount0,
        uint256 _amount1,
        address /* _receiver */
    ) internal view returns (MintProceeds memory proceeds) {
        (uint256 shares, uint256 fee0, uint256 fee1,) =
            _vault.amountsToShares(_reg, S.tres(), _amount0, _amount1, FeeType.ENTRY, address(0));
        proceeds.shares = uint128(shares);
        proceeds.protocolFee0 = uint128(fee0);
        proceeds.protocolFee1 = uint128(fee1);
        proceeds.spent0 = _amount0;
        proceeds.spent1 = _amount1;
    }

    function previewDepositExact0(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _exactAmount0,
        address /* _receiver */
    ) internal view returns (MintProceeds memory proceeds) {
        uint256 ratio0 = _vault.targetRatio0(_reg);
        if (_exactAmount0 == 0 || ratio0 == M.PREC_BPS) {
            return MintProceeds({spent0: 0, spent1: 0, shares: 0, protocolFee0: 0, protocolFee1: 0});
        }

        uint256 ratio1 = M.PREC_BPS - ratio0;
        if (ratio1 == 0) revert Errors.ZeroValue();

        proceeds.spent1 = ratio1.mulDivDown(_exactAmount0, ratio0);
        proceeds.spent0 = _exactAmount0;
    }

    function previewDepositExact1(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _exactAmount1,
        address /* _receiver */
    ) internal view returns (MintProceeds memory proceeds) {
        uint256 ratio1 = _vault.targetRatio1(_reg);
        if (_exactAmount1 == 0 || ratio1 == M.PREC_BPS) {
            return MintProceeds({spent0: 0, spent1: 0, shares: 0, protocolFee0: 0, protocolFee1: 0});
        }

        uint256 ratio0 = M.PREC_BPS - ratio1;
        if (ratio0 == 0) revert Errors.ZeroValue();

        proceeds.spent0 = ratio0.mulDivDown(_exactAmount1, ratio1);
        proceeds.spent1 = _exactAmount1;
    }

    function previewMint(
        ALMVault storage, /* _vault */
        Registry storage, /* _reg */
        uint256 _shares,
        address /* _receiver */
    ) internal pure returns (MintProceeds memory proceeds) {
        proceeds.shares = uint128(_shares);
    }

    function previewRedeem(
        ALMVault storage, /* _vault */
        Registry storage, /* _reg */
        uint256, /* _shares */
        address /* _receiver */
    ) internal pure returns (BurnProceeds memory proceeds) {
        // Basic return values only to avoid stack too deep
    }

    function previewWithdraw(
        ALMVault storage, /* _vault */
        Registry storage, /* _reg */
        uint256 _amount0,
        uint256 _amount1,
        address /* _receiver */
    ) internal pure returns (BurnProceeds memory proceeds) {
        proceeds.recovered0 = _amount0;
        proceeds.recovered1 = _amount1;
    }

    function previewWithdrawExact0(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _exactAmount0,
        address /* _receiver */
    ) internal view returns (BurnProceeds memory proceeds) {
        uint256 ratio0 = _vault.targetRatio0(_reg);
        if (_exactAmount0 == 0 || ratio0 == M.PREC_BPS) {
            return BurnProceeds({recovered0: 0, recovered1: 0, lpFee0: 0, lpFee1: 0, protocolFee0: 0, protocolFee1: 0});
        }
        uint256 ratio1 = M.PREC_BPS - ratio0;
        if (ratio1 == 0) revert Errors.ZeroValue();

        proceeds.recovered1 = ratio1.mulDivDown(_exactAmount0, ratio0);
        proceeds.recovered0 = _exactAmount0;
    }

    function previewWithdrawExact1(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _exactAmount1,
        address /* _receiver */
    ) internal view returns (BurnProceeds memory proceeds) {
        uint256 ratio1 = _vault.targetRatio1(_reg);
        if (_exactAmount1 == 0 || ratio1 == M.PREC_BPS) {
            return BurnProceeds({recovered0: 0, recovered1: 0, lpFee0: 0, lpFee1: 0, protocolFee0: 0, protocolFee1: 0});
        }

        uint256 ratio0 = M.PREC_BPS - ratio1;
        if (ratio0 == 0) revert Errors.ZeroValue();

        proceeds.recovered0 = ratio0.mulDivDown(_exactAmount1, ratio1);
        proceeds.recovered1 = _exactAmount1;
    }

    function previewDepositMax(
        ALMVault storage _vault,
        Registry storage, /* _reg */
        address _payer,
        address /* _receiver */
    ) internal view returns (uint256 deposit0, uint256 deposit1) {
        deposit0 = _vault.token0.balanceOf(_payer);
        deposit1 = _vault.token1.balanceOf(_payer);
    }

    function mintShares(
        ALMVault storage _vault,
        uint256 _net0,
        uint256 _net1,
        uint256 _entryFee0,
        uint256 _entryFee1,
        uint256 _sharesToMint,
        address _receiver
    ) internal {
        if (_sharesToMint == 0) revert Errors.ZeroValue();

        _vault.token0.safeTransferFrom(msg.sender, address(this), _net0); // User pays net0
        _vault.token1.safeTransferFrom(msg.sender, address(this), _net1); // User pays net1

        (uint256 gross0, uint256 gross1) = (M.subMax0(_net0, _entryFee0), M.subMax0(_net1, _entryFee1));

        if (_entryFee0 > 0) _vault.pendingFees[address(_vault.token0)] += _entryFee0; // Collect entry fee0
        if (_entryFee1 > 0) _vault.pendingFees[address(_vault.token1)] += _entryFee1; // Collect entry fee1
        if (gross0 > 0) _vault.cash[address(_vault.token0)] += gross0; // Vault receives gross0
        if (gross1 > 0) _vault.cash[address(_vault.token1)] += gross1; // Vault receives gross1
        LibERC1155.mint(_vault, S.rst(), _receiver, _sharesToMint); // User receives shares

        emit Events.SharesMinted(msg.sender, _receiver, _sharesToMint, gross0, gross1, _entryFee0, _entryFee1);
    }

    function burnShares(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _gross0, // Protocol gross burn == user net exit
        uint256 _gross1, // Protocol gross burn == user net exit
        uint256 _exitFee0,
        uint256 _exitFee1,
        uint256 _burn,
        address _receiver
    ) internal {
        if (_burn == 0 || _gross0 == 0 || _gross1 == 0) revert Errors.ZeroValue();

        if (_vault.totalSupply < _burn) revert Errors.Insufficient(_vault.totalSupply, _burn);
        if (LibERC1155.balanceOf(_vault, msg.sender) < _burn) {
            revert Errors.Insufficient(LibERC1155.balanceOf(_vault, msg.sender), _burn);
        }

        LibERC1155.burn(_vault, S.rst(), msg.sender, _burn);

        // Check if we need to burn ranges first
        if ((_gross0 + _exitFee0) > _vault.cash0() || (_gross1 + _exitFee1) > _vault.cash1()) {
            BurnProceeds memory result = ALMB.burnRanges(_vault, _reg, false);
            _vault.accrueAlmFees(_reg, result.lpFee0, result.lpFee1);
        }

        uint256 totalNet0 = _gross0 + _exitFee0;
        uint256 totalNet1 = _gross1 + _exitFee1;

        if (_vault.cash0() < totalNet0) revert Errors.Insufficient(_vault.cash0(), totalNet0);
        if (_vault.cash1() < totalNet1) revert Errors.Insufficient(_vault.cash1(), totalNet1);

        if (_exitFee0 > 0) _vault.pendingFees[address(_vault.token0)] += _exitFee0;
        if (_exitFee1 > 0) _vault.pendingFees[address(_vault.token1)] += _exitFee1;

        _vault.cash[address(_vault.token0)] -= totalNet0;
        _vault.cash[address(_vault.token1)] -= totalNet1;

        _vault.token0.safeTransfer(_receiver, _gross0);
        _vault.token1.safeTransfer(_receiver, _gross1);

        emit Events.SharesBurnt(msg.sender, _receiver, _burn, _gross0, _gross1, _exitFee0, _exitFee1);
    }

    function mint(ALMVault storage _vault, Registry storage _reg, uint256 _shares, address _receiver)
        internal
        returns (MintProceeds memory proceeds)
    {
        proceeds = previewMint(_vault, _reg, _shares, _receiver);
        mintShares(
            _vault, proceeds.spent0, proceeds.spent1, proceeds.protocolFee0, proceeds.protocolFee1, _shares, _receiver
        );
    }

    function deposit(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount0,
        uint256 _amount1,
        address _receiver
    ) internal returns (MintProceeds memory proceeds) {
        if (_amount0 + _amount1 == 0) revert Errors.ZeroValue();
        proceeds = previewDeposit(_vault, _reg, _amount0, _amount1, _receiver);
        mintShares(_vault, _amount0, _amount1, proceeds.protocolFee0, proceeds.protocolFee1, proceeds.shares, _receiver);
    }

    function depositExact0(ALMVault storage _vault, Registry storage _reg, uint256 _exactAmount0, address _receiver)
        internal
        returns (MintProceeds memory proceeds)
    {
        if (_exactAmount0 == 0) revert Errors.ZeroValue();
        proceeds = previewDepositExact0(_vault, _reg, _exactAmount0, _receiver);
        mintShares(
            _vault,
            _exactAmount0,
            proceeds.spent1,
            proceeds.protocolFee0,
            proceeds.protocolFee1,
            proceeds.shares,
            _receiver
        );
    }

    function depositExact1(ALMVault storage _vault, Registry storage _reg, uint256 _exactAmount1, address _receiver)
        internal
        returns (MintProceeds memory proceeds)
    {
        if (_exactAmount1 == 0) revert Errors.ZeroValue();
        proceeds = previewDepositExact1(_vault, _reg, _exactAmount1, _receiver);
        mintShares(
            _vault,
            proceeds.spent0,
            _exactAmount1,
            proceeds.protocolFee0,
            proceeds.protocolFee1,
            proceeds.shares,
            _receiver
        );
    }

    function redeem(ALMVault storage _vault, Registry storage _reg, uint256 _shares, address _receiver)
        internal
        returns (BurnProceeds memory proceeds)
    {
        proceeds = previewRedeem(_vault, _reg, _shares, _receiver);
        burnShares(
            _vault,
            _reg,
            proceeds.recovered0,
            proceeds.recovered1,
            proceeds.protocolFee0,
            proceeds.protocolFee1,
            _shares,
            _receiver
        );
    }

    function withdraw(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _amount0,
        uint256 _amount1,
        address _receiver
    ) internal returns (BurnProceeds memory proceeds) {
        if (_amount0 == 0 && _amount1 == 0) revert Errors.ZeroValue();
        proceeds = previewWithdraw(_vault, _reg, _amount0, _amount1, _receiver);
        (uint256 burn,,,) = _vault.amountsToShares(_reg, S.tres(), _amount0, _amount1, FeeType.EXIT, _receiver);
        if (burn == 0) revert Errors.ZeroValue();
        burnShares(
            _vault,
            _reg,
            _amount0,
            _amount1,
            uint256(proceeds.protocolFee0),
            uint256(proceeds.protocolFee1),
            burn,
            _receiver
        );
    }

    function withdrawExact0(ALMVault storage _vault, Registry storage _reg, uint256 _exactAmount0, address _receiver)
        internal
        returns (BurnProceeds memory proceeds)
    {
        if (_exactAmount0 == 0) revert Errors.ZeroValue();
        proceeds = previewWithdrawExact0(_vault, _reg, _exactAmount0, _receiver);
        (uint256 burn,,,) =
            _vault.amountsToShares(_reg, S.tres(), _exactAmount0, proceeds.recovered1, FeeType.EXIT, _receiver);
        burnShares(
            _vault,
            _reg,
            _exactAmount0,
            proceeds.recovered1,
            uint256(proceeds.protocolFee0),
            uint256(proceeds.protocolFee1),
            burn,
            _receiver
        );
    }

    function withdrawExact1(ALMVault storage _vault, Registry storage _reg, uint256 _exactAmount1, address _receiver)
        internal
        returns (BurnProceeds memory proceeds)
    {
        if (_exactAmount1 == 0) revert Errors.ZeroValue();
        proceeds = previewWithdrawExact1(_vault, _reg, _exactAmount1, _receiver);
        (uint256 burn,,,) =
            _vault.amountsToShares(_reg, S.tres(), proceeds.recovered0, _exactAmount1, FeeType.EXIT, _receiver);
        burnShares(
            _vault,
            _reg,
            proceeds.recovered0,
            _exactAmount1,
            uint256(proceeds.protocolFee0),
            uint256(proceeds.protocolFee1),
            burn,
            _receiver
        );
    }

    function depositSingle0(ALMVault storage _vault, Registry storage _reg, uint256 _amount0, address _receiver)
        internal
        returns (MintProceeds memory proceeds)
    {
        if (_amount0 == 0) revert Errors.ZeroValue();
        (uint256 shares,,,) = _vault.amountsToShares(_reg, S.tres(), _amount0, 0, FeeType.ENTRY, _receiver);
        if (shares == 0) revert Errors.ZeroValue();
        proceeds.shares = uint128(shares);
        proceeds.spent0 = _amount0;
        proceeds.spent1 = 0;
        mintShares(_vault, _amount0, 0, 0, 0, shares, _receiver);
    }

    function depositSingle1(ALMVault storage _vault, Registry storage _reg, uint256 _amount1, address _receiver)
        internal
        returns (MintProceeds memory proceeds)
    {
        if (_amount1 == 0) revert Errors.ZeroValue();
        (uint256 shares,,,) = _vault.amountsToShares(_reg, S.tres(), 0, _amount1, FeeType.ENTRY, _receiver);
        if (shares == 0) revert Errors.ZeroValue();
        proceeds.shares = uint128(shares);
        proceeds.spent0 = 0;
        proceeds.spent1 = _amount1;
        mintShares(_vault, 0, _amount1, 0, 0, shares, _receiver);
    }

    function withdrawSingle0(ALMVault storage _vault, Registry storage _reg, uint256 _shares, address _receiver)
        internal
        returns (BurnProceeds memory proceeds)
    {
        if (_shares == 0) revert Errors.ZeroValue();

        // Get the amount of token0 for the shares
        (uint256 amount0,,,) = _vault.sharesToAmount0(_reg, S.tres(), _shares, FeeType.EXIT, _receiver);
        proceeds.recovered0 = amount0;
        proceeds.recovered1 = 0;

        _processWithdrawSingle0(_vault, _reg, _shares, _receiver, amount0, 0);
    }

    function _processWithdrawSingle0(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _shares,
        address _receiver,
        uint256 amount0,
        uint256 fee0
    ) private {
        uint256 balance = LibERC1155.balanceOf(_vault, msg.sender);
        if (_vault.totalSupply < _shares) revert Errors.Insufficient(_vault.totalSupply, _shares);
        if (balance < _shares) revert Errors.Insufficient(balance, _shares);

        LibERC1155.burn(_vault, S.rst(), msg.sender, _shares);

        bool cascading = _ensureCash0(_vault, _reg, amount0 + fee0);

        address tokenAddr = address(_vault.token0);
        if (fee0 > 0) {
            _vault.pendingFees[tokenAddr] += fee0;
        }

        _vault.cash[tokenAddr] -= (amount0 + fee0);
        _vault.token0.safeTransfer(_receiver, amount0);

        if (cascading) _vault.remintRanges(_reg);
        emit Events.SharesBurnt(msg.sender, _receiver, _shares, amount0, 0, fee0, 0);
    }

    function _ensureCash0(ALMVault storage _vault, Registry storage _reg, uint256 required)
        private
        returns (bool cascading)
    {
        uint256 cash0 = _vault.cash0();

        // If we don't have enough cash, burn ranges to get more
        if (required > cash0) {
            cascading = true;
            BurnProceeds memory burnResult = ALMB.burnRanges(_vault, _reg, false);
            _vault.accrueAlmFees(_reg, burnResult.lpFee0, burnResult.lpFee1);
            cash0 += burnResult.recovered0;
        }

        if (cash0 < required) {
            revert Errors.Insufficient(cash0, required);
        }
    }

    function withdrawSingle1(ALMVault storage _vault, Registry storage _reg, uint256 _shares, address _receiver)
        internal
        returns (BurnProceeds memory proceeds)
    {
        if (_shares == 0) revert Errors.ZeroValue();

        // Get the amount of token1 for the shares
        (uint256 amount1,,,) = _vault.sharesToAmount1(_reg, S.tres(), _shares, FeeType.EXIT, _receiver);
        proceeds.recovered0 = 0;
        proceeds.recovered1 = amount1;

        _processWithdrawSingle1(_vault, _reg, _shares, _receiver, amount1, 0);
    }

    function _processWithdrawSingle1(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _shares,
        address _receiver,
        uint256 amount1,
        uint256 fee1
    ) private {
        uint256 balance = LibERC1155.balanceOf(_vault, msg.sender);
        if (_vault.totalSupply < _shares) revert Errors.Insufficient(_vault.totalSupply, _shares);
        if (balance < _shares) revert Errors.Insufficient(balance, _shares);

        LibERC1155.burn(_vault, S.rst(), msg.sender, _shares);

        bool cascading = _ensureCash1(_vault, _reg, amount1 + fee1);

        address tokenAddr = address(_vault.token1);
        if (fee1 > 0) {
            _vault.pendingFees[tokenAddr] += fee1;
        }

        _vault.cash[tokenAddr] -= (amount1 + fee1);
        _vault.token1.safeTransfer(_receiver, amount1);

        if (cascading) _vault.remintRanges(_reg);
        emit Events.SharesBurnt(msg.sender, _receiver, _shares, 0, amount1, 0, fee1);
    }

    function _ensureCash1(ALMVault storage _vault, Registry storage _reg, uint256 required)
        private
        returns (bool cascading)
    {
        uint256 cash1 = _vault.cash1();

        // If we don't have enough cash, burn ranges to get more
        if (required > cash1) {
            cascading = true;
            BurnProceeds memory burnResult = ALMB.burnRanges(_vault, _reg, false);
            _vault.accrueAlmFees(_reg, burnResult.lpFee0, burnResult.lpFee1);
            cash1 += burnResult.recovered1;
        }

        if (cash1 < required) {
            revert Errors.Insufficient(cash1, required);
        }
    }
}
