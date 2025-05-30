// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors, ErrorType} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Permissioned Facet Base - Abstract base for permissioned facets
 * @copyright 2025
 * @notice Provides modifiers and helpers for access-controlled facet functions
 * @dev Inherits from Permissioned abstract contract
 * @author BTR Team
 */

abstract contract PermissionedFacet {
    modifier onlyRole(bytes32 _role) virtual {
        AC.checkRole(S.acc(), _role); // Verify caller has the role
        _;
    }

    modifier onlyRoleAdmin(bytes32 _role) virtual {
        AC.checkRoleAdmin(S.acc(), _role); // Verify caller is an admin of the role
        _;
    }

    modifier onlyDiamond() virtual {
        if (msg.sender != address(this)) revert Errors.Unauthorized(ErrorType.ACCESS);
        _;
    }

    modifier onlyAdmin() virtual {
        AC.checkRole(S.acc(), AC.ADMIN_ROLE); // Verify caller is an admin
        _;
    }

    modifier onlyManager() virtual {
        AC.checkRole(S.acc(), AC.MANAGER_ROLE); // Verify caller is a manager
        _;
    }

    modifier onlyKeeper() virtual {
        AC.checkRole(S.acc(), AC.KEEPER_ROLE); // Verify caller is a keeper
        _;
    }

    modifier onlyTreasury() virtual {
        AC.checkRole(S.acc(), AC.TREASURY_ROLE); // Verify caller is the treasury
        _;
    }

    function hasRole(bytes32 _role, address _account) public view returns (bool) {
        return AC.hasRole(S.acc(), _role, _account); // Check if account has role
    }

    function checkRole(bytes32 _role) public view {
        AC.checkRole(S.acc(), _role); // Verify caller has role
    }

    function checkRole(bytes32 _role, address _account) public view {
        AC.checkRole(S.acc(), _role, _account); // Verify account has role
    }

    function isDiamond(address _account) external view returns (bool) {
        return _account == address(this);
    }

    function isAdmin(address _account) external view returns (bool) {
        return hasRole(AC.ADMIN_ROLE, _account); // Check if account is admin
    }

    function isManager(address _account) external view returns (bool) {
        return hasRole(AC.MANAGER_ROLE, _account); // Check if account is manager
    }

    function isKeeper(address _account) external view returns (bool) {
        return hasRole(AC.KEEPER_ROLE, _account); // Check if account is keeper
    }

    function isTreasury(address _account) external view returns (bool) {
        return hasRole(AC.TREASURY_ROLE, _account); // Check if account is treasury
    }

    function diamond() external view virtual returns (address) {
        return address(this); // Get the diamond address
    }

    function admin() external view virtual returns (address) {
        return AC.admin(S.acc()); // Get the admin address
    }

    function tres() external view virtual returns (address) {
        return AC.treasury(S.acc()); // Get the treasury address
    }

    function managers() external view virtual returns (address[] memory) {
        return AC.members(S.acc(), AC.MANAGER_ROLE); // Get all managers
    }

    function keepers() external view virtual returns (address[] memory) {
        return AC.members(S.acc(), AC.KEEPER_ROLE); // Get all keepers
    }

    function isBlacklisted(address _account) external view virtual returns (bool) {
        return AC.isBlacklisted(S.rst(), _account); // Check if account is blacklisted
    }

    function isWhitelisted(address _account) external view virtual returns (bool) {
        return AC.isWhitelisted(S.rst(), _account); // Check if account is whitelisted
    }
}
