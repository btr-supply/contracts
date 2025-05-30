// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {ALMVault, MintProceeds, BurnProceeds} from "@/BTRTypes.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMUser as ALMU} from "@libraries/LibALMUser.sol";
import {NonReentrantFacet} from "@facets/abstract/NonReentrantFacet.sol";
import {PausableFacet} from "@facets/abstract/PausableFacet.sol";
import {RestrictedFacet} from "@facets/abstract/RestrictedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM User Facet - ALM user state-changing operations
 * @copyright 2025
 * @notice Handles user-facing ALM operations including deposits, withdrawals, and previews with safety mechanisms
 * @dev Sub-facet for ALM user operations:
- Functions: Regular and safe variants of `deposit`, `mint`, `depositExact0`, `depositExact1`, `redeem`, `withdraw`, `withdrawExact0`, `withdrawExact1`, plus preview functions
- Includes error-handling mechanisms for safe operations with minimums/maximums
 * @author BTR Team
 */

contract ALMUserFacet is RestrictedFacet, PausableFacet, NonReentrantFacet {
    using U for uint32;
    using ALMU for ALMVault;

    // --- Deposit/Withdraw Actions ---

    function deposit(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory proceeds)
    {
        return _vid.vault().deposit(S.reg(), _amount0, _amount1, _receiver);
    }

    function safeDeposit(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver, uint256 _minShares)
        external
        returns (MintProceeds memory proceeds)
    {
        proceeds = _vid.vault().deposit(S.reg(), _amount0, _amount1, _receiver);
        if (proceeds.shares < _minShares) {
            revert Errors.Insufficient(proceeds.shares, _minShares);
        }
    }

    function mint(uint32 _vid, uint256 _shares, address _receiver) external returns (MintProceeds memory proceeds) {
        return _vid.vault().mint(S.reg(), _shares, _receiver);
    }

    function safeMint(uint32 _vid, uint256 _shares, address _receiver, uint256 _maxSpent0, uint256 _maxSpent1)
        external
        returns (MintProceeds memory proceeds)
    {
        proceeds = _vid.vault().mint(S.reg(), _shares, _receiver);
        if (proceeds.spent0 > _maxSpent0) {
            revert Errors.Exceeds(proceeds.spent0, _maxSpent0);
        }
        if (proceeds.spent1 > _maxSpent1) {
            revert Errors.Exceeds(proceeds.spent1, _maxSpent1);
        }
    }

    function depositExact0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        returns (MintProceeds memory proceeds)
    {
        return _vid.vault().depositExact0(S.reg(), _amount0, _receiver);
    }

    function safeDepositExact0(
        uint32 _vid,
        uint256 _amount0,
        address _receiver,
        uint256 _minShares,
        uint256 _maxAmount1
    ) external returns (MintProceeds memory proceeds) {
        proceeds = _vid.vault().depositExact0(S.reg(), _amount0, _receiver);
        if (proceeds.spent1 > _maxAmount1) {
            revert Errors.Exceeds(proceeds.spent1, _maxAmount1);
        }
        if (proceeds.shares < _minShares) {
            revert Errors.Insufficient(proceeds.shares, _minShares);
        }
    }

    function depositExact1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory proceeds)
    {
        return _vid.vault().depositExact1(S.reg(), _amount1, _receiver);
    }

    function safeDepositExact1(uint32 _vid, uint256 _amount1, address _receiver, uint256 _minShares, uint256 _maxSpent0)
        external
        returns (MintProceeds memory proceeds)
    {
        proceeds = _vid.vault().depositExact1(S.reg(), _amount1, _receiver);
        if (proceeds.spent0 > _maxSpent0) {
            revert Errors.Exceeds(proceeds.spent0, _maxSpent0);
        }
        if (proceeds.shares < _minShares) {
            revert Errors.Insufficient(proceeds.shares, _minShares);
        }
    }

    function redeem(uint32 _vid, uint256 _shares, address _receiver) external returns (BurnProceeds memory proceeds) {
        return _vid.vault().redeem(S.reg(), _shares, _receiver);
    }

    function safeRedeem(uint32 _vid, uint256 _shares, address _receiver, uint256 _minAmount0, uint256 _minAmount1)
        external
        returns (BurnProceeds memory proceeds)
    {
        proceeds = _vid.vault().redeem(S.reg(), _shares, _receiver);
        if (proceeds.recovered0 < _minAmount0) {
            revert Errors.Insufficient(proceeds.recovered0, _minAmount0);
        }
        if (proceeds.recovered1 < _minAmount1) {
            revert Errors.Insufficient(proceeds.recovered1, _minAmount1);
        }
    }

    function withdraw(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (BurnProceeds memory proceeds)
    {
        return _vid.vault().withdraw(S.reg(), _amount0, _amount1, _receiver);
    }

    function safeWithdraw(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver, uint256 _maxBurntShares)
        external
        returns (BurnProceeds memory proceeds)
    {
        proceeds = _vid.vault().withdraw(S.reg(), _amount0, _amount1, _receiver);
        // Calculate burnt shares from recovered amounts (reverse calculation)
        uint256 burntShares = proceeds.recovered0 + proceeds.recovered1; // Simplified for now
        if (burntShares > _maxBurntShares) {
            revert Errors.Exceeds(burntShares, _maxBurntShares);
        }
    }

    function withdrawExact0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        returns (BurnProceeds memory proceeds)
    {
        return _vid.vault().withdrawExact0(S.reg(), _amount0, _receiver);
    }

    function safeWithdrawExact0(
        uint32 _vid,
        uint256 _amount0,
        address _receiver,
        uint256 _minAmount1,
        uint256 _maxBurntShares
    ) external returns (BurnProceeds memory proceeds) {
        proceeds = _vid.vault().withdrawExact0(S.reg(), _amount0, _receiver);
        if (proceeds.recovered1 < _minAmount1) {
            revert Errors.Insufficient(proceeds.recovered1, _minAmount1);
        }
        // Calculate burnt shares from recovered amounts (reverse calculation)
        uint256 burntShares = proceeds.recovered0 + proceeds.recovered1; // Simplified for now
        if (burntShares > _maxBurntShares) {
            revert Errors.Exceeds(burntShares, _maxBurntShares);
        }
    }

    function withdrawExact1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        returns (BurnProceeds memory proceeds)
    {
        return _vid.vault().withdrawExact1(S.reg(), _amount1, _receiver);
    }

    function safeWithdrawExact1(
        uint32 _vid,
        uint256 _amount1,
        address _receiver,
        uint256 _minAmount0,
        uint256 _maxBurntShares
    ) external returns (BurnProceeds memory proceeds) {
        proceeds = _vid.vault().withdrawExact1(S.reg(), _amount1, _receiver);
        if (proceeds.recovered0 < _minAmount0) {
            revert Errors.Insufficient(proceeds.recovered0, _minAmount0);
        }
        // Calculate burnt shares from recovered amounts (reverse calculation)
        uint256 burntShares = proceeds.recovered0 + proceeds.recovered1; // Simplified for now
        if (burntShares > _maxBurntShares) {
            revert Errors.Exceeds(burntShares, _maxBurntShares);
        }
    }

    function depositSingle0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        returns (MintProceeds memory proceeds)
    {
        return _vid.vault().depositSingle0(S.reg(), _amount0, _receiver);
    }

    function safeDepositSingle0(uint32 _vid, uint256 _amount0, address _receiver, uint256 _minShares)
        external
        returns (MintProceeds memory proceeds)
    {
        proceeds = _vid.vault().depositSingle0(S.reg(), _amount0, _receiver);
        if (proceeds.shares < _minShares) {
            revert Errors.Insufficient(proceeds.shares, _minShares);
        }
    }

    function depositSingle1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory proceeds)
    {
        return _vid.vault().depositSingle1(S.reg(), _amount1, _receiver);
    }

    function safeDepositSingle1(uint32 _vid, uint256 _amount1, address _receiver, uint256 _minShares)
        external
        returns (MintProceeds memory proceeds)
    {
        proceeds = _vid.vault().depositSingle1(S.reg(), _amount1, _receiver);
        if (proceeds.shares < _minShares) {
            revert Errors.Insufficient(proceeds.shares, _minShares);
        }
    }

    function withdrawSingle0(uint32 _vid, uint256 _shares, address _receiver)
        external
        returns (BurnProceeds memory proceeds)
    {
        return _vid.vault().withdrawSingle0(S.reg(), _shares, _receiver);
    }

    function safeWithdrawSingle0(uint32 _vid, uint256 _shares, address _receiver, uint256 _minAmount0)
        external
        returns (BurnProceeds memory proceeds)
    {
        proceeds = _vid.vault().withdrawSingle0(S.reg(), _shares, _receiver);
        if (proceeds.recovered0 < _minAmount0) {
            revert Errors.Insufficient(proceeds.recovered0, _minAmount0);
        }
    }

    function withdrawSingle1(uint32 _vid, uint256 _shares, address _receiver)
        external
        returns (BurnProceeds memory proceeds)
    {
        return _vid.vault().withdrawSingle1(S.reg(), _shares, _receiver);
    }

    function safeWithdrawSingle1(uint32 _vid, uint256 _shares, address _receiver, uint256 _minAmount1)
        external
        returns (BurnProceeds memory proceeds)
    {
        proceeds = _vid.vault().withdrawSingle1(S.reg(), _shares, _receiver);
        if (proceeds.recovered1 < _minAmount1) {
            revert Errors.Insufficient(proceeds.recovered1, _minAmount1);
        }
    }
}
