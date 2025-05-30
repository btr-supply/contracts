// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccountStatus as AS, AddressType, ErrorType, Fees, CoreStorage, ALMVault} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibDiamond} from "@libraries/LibDiamond.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {LibManagement as M} from "@libraries/LibManagement.sol";
import {LibPausable as P} from "@libraries/LibPausable.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
import {NonReentrantFacet} from "@facets/abstract/NonReentrantFacet.sol";
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
 * @title Management Facet - Protocol parameter management
 * @copyright 2025
 * @notice Allows authorized addresses to update protocol settings and parameters
 * @dev Governs protocol configuration (pauses, whitelists, restrictions)
- Security Critical: Controls pausing, account status, minting restrictions, swap parameters
- Modifiers: Primarily uses `onlyManager` to secure parameter changes. `initializeManagement` uses `onlyAdmin`
- Manages swap/bridge restrictions and vault-level settings

 * @author BTR Team
 */

contract ManagementFacet is PermissionedFacet, NonReentrantFacet {
    using M for address;
    using P for uint32;

    // --- INITIALIZATION ---

    function initializeManagement() external onlyAdmin {
        M.initialize(
            S.rst(), // restrictions storage
            false, // restrictSwapCaller
            false, // restrictSwapRouter
            false, // restrictSwapInput
            false, // restrictSwapOutput
            true, // approveMax
            true // autoRevoke
        );
    }

    // --- PAUSE ---

    function pause() external onlyManager {
        P.pause();
    }

    function unpause() external onlyManager {
        P.unpause();
    }

    // --- MANAGEMENT ---

    function setVersion(uint8 _version) external onlyAdmin {
        M.setVersion(S.core(), _version);
    }

    // --- CUSTOM FEES ---

    function setCustomFees(address _user, Fees calldata _fees) external onlyManager nonReentrant {
        T.setCustomFees(S.tres(), _user, _fees);
    }

    // --- WHITELISTED/BLACKLISTED ---

    function setAccountStatus(address _account, AS _status) external onlyManager {
        AC.setAccountStatus(S.rst(), _account, _status);
    }

    function setAccountStatusBatch(address[] calldata _accounts, AS _status) external onlyManager {
        AC.setAccountStatusBatch(S.rst(), _accounts, _status);
    }

    // --- WHITELISTED/BLACKLISTED ---

    function addToWhitelist(address _account) external onlyManager {
        AC.addToWhitelist(S.rst(), _account);
    }

    function removeFromList(address _account) external onlyManager {
        AC.removeFromList(S.rst(), _account);
    }

    function addToBlacklist(address _account) external onlyManager {
        AC.addToBlacklist(S.rst(), _account);
    }

    function addToListBatch(address[] calldata _accounts, AS _status) external onlyManager {
        AC.addToListBatch(S.rst(), _accounts, _status);
    }

    function removeFromListBatch(address[] calldata _accounts) external onlyManager {
        AC.removeFromListBatch(S.rst(), _accounts);
    }

    // --- RESTRICTION MANAGEMENT ---

    function setSwapCallerRestriction(bool _value) external onlyManager {
        M.setSwapCallerRestriction(S.rst(), _value);
    }

    function setSwapRouterRestriction(bool _value) external onlyManager {
        M.setSwapRouterRestriction(S.rst(), _value);
    }

    function setSwapInputRestriction(bool _value) external onlyManager {
        M.setSwapInputRestriction(S.rst(), _value);
    }

    function setSwapOutputRestriction(bool _value) external onlyManager {
        M.setSwapOutputRestriction(S.rst(), _value);
    }

    function setBridgeInputRestriction(bool _value) external onlyManager {
        M.setBridgeInputRestriction(S.rst(), _value);
    }

    function setBridgeOutputRestriction(bool _value) external onlyManager {
        M.setBridgeOutputRestriction(S.rst(), _value);
    }

    function setBridgeRouterRestriction(bool _value) external onlyManager {
        M.setBridgeRouterRestriction(S.rst(), _value);
    }

    function setApproveMax(bool _value) external onlyManager {
        M.setApproveMax(S.rst(), _value);
    }

    function setAutoRevoke(bool _value) external onlyManager {
        M.setAutoRevoke(S.rst(), _value);
    }
}
