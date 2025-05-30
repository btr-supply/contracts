// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccessControl, PendingAcceptance, ErrorType} from "@/BTRTypes.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {IERC173} from "@interfaces/ercs/IERC173.sol";
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
 * @title Access Control Facet - Role-based access control management
 * @copyright 2025
 * @notice Manages roles, permissions, and grants/revokes access for protocol functions
 * @dev Implements role-based access control using `LibAccessControl`
- Security Critical: Foundation of permission system (`ADMIN_ROLE`, `MANAGER_ROLE`, `KEEPER_ROLE`, `TREASURY_ROLE`)
- Modifiers: `setRoleAdmin`, `grantRole`, `revokeRole`, `renounceRole` typically require `DEFAULT_ADMIN_ROLE` (or role's admin). `transferOwnership` uses `onlyAdmin`

 * @author BTR Team
 */

contract AccessControlFacet is PermissionedFacet, NonReentrantFacet, IERC173 {
    // --- ERC-173 COMPLIANCE ---
    function owner() external view override returns (address) {
        return AC.admin(S.acc());
    }

    function transferOwnership(address _newOwner) external override {
        if (_newOwner == address(0)) revert Errors.ZeroAddress();
        AC.safeGrantRole(S.acc(), AC.ADMIN_ROLE, _newOwner, msg.sender);
    }

    // --- VIEWS ---

    function members(bytes32 _role) external view returns (address[] memory) {
        return AC.members(S.acc(), _role);
    }

    function timelockConfig() external view returns (uint256 grantDelay, uint256 acceptanceTtl) {
        return AC.timelockConfig(S.acc());
    }

    function checkRoleAcceptance(PendingAcceptance calldata _acceptance, bytes32 _role) external view {
        AC.checkRoleAcceptance(S.acc(), _acceptance, _role);
    }

    function getPendingAcceptance(address _account)
        external
        view
        returns (bytes32 pendingRole, address replacing, uint64 timestamp)
    {
        PendingAcceptance memory acceptance = AC.getPendingAcceptance(S.acc(), _account);
        return (acceptance.role, acceptance.replacing, acceptance.timestamp);
    }

    // --- CONFIGURATION ---

    function initializeAccessControl() external {
        // No-op since initialization is handled in the diamond constructor
    }

    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external {
        AC.setRoleAdmin(S.acc(), _role, _adminRole);
    }

    function setTimelockConfig(uint256 _grantDelay, uint256 _acceptanceTtl) external {
        AC.setTimelockConfig(S.acc(), _grantDelay, _acceptanceTtl);
    }

    function grantRole(bytes32 _role, address _account) external {
        AC.safeGrantRole(S.acc(), _role, _account, msg.sender);
    }

    function revokeRole(bytes32 _role, address _account) external {
        AC.revokeRole(S.acc(), _role, _account);
    }

    function renounceRole(bytes32 _role) external {
        AC.revokeRole(S.acc(), _role, msg.sender);
    }

    function acceptRole(bytes32 /* _role */ ) external nonReentrant {
        AC.acceptRole(S.acc(), S.res(), msg.sender);
    }

    function cancelRoleGrant(address _account) external {
        AC.cancelRoleGrant(S.acc(), _account);
    }

    function revokeAll(bytes32 _role) external {
        AC.revokeAll(S.acc(), _role);
    }

    function revokeAllManagers() external {
        AC.revokeAllManagers(S.acc());
    }

    function revokeAllKeepers() external {
        AC.revokeAllKeepers(S.acc());
    }
}
