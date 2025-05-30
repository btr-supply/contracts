// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {IPermissioned} from "@interfaces/IPermissioned.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Permissioned Base - Base contract for permissioned access
 * @copyright 2025
 * @notice Abstract contract providing role-based access control hooks
 * @dev Integrates with AccessControl implementation using diamond storage
 * @author BTR Team
 */

abstract contract Permissioned {
    IPermissioned public diamond;

    constructor(address _diamond) {
        _setDiamond(_diamond);
    }

    function _setDiamond(address _diamond) internal {
        if (_diamond == address(0)) revert Errors.ZeroAddress();
        if (_diamond == diamond) revert Errors.AlreadyInitialized();
        diamond = IPermissioned(_diamond);
    }

    function setDiamond(address _diamond) external onlyAdmin {
        _setDiamond(_diamond);
    }

    modifier onlyRole(bytes32 _role) virtual {
        diamond.checkRole(_role, msg.sender);
        _;
    }

    modifier onlyDiamond() virtual {
        if (msg.sender != address(diamond)) revert Errors.NotDiamond();
        _;
    }

    modifier onlyAdmin() virtual {
        diamond.isAdmin(msg.sender);
        _;
    }

    modifier onlyManager() virtual {
        diamond.isManager(msg.sender);
        _;
    }

    modifier onlyManagerFor(address _account) virtual {
        diamond.isManager(_account);
        _;
    }

    modifier onlyKeeper() virtual {
        diamond.isKeeper(msg.sender);
        _;
    }

    modifier onlyKeeperFor(address _account) virtual {
        diamond.isKeeper(_account);
        _;
    }

    modifier onlyTreasury() virtual {
        diamond.isTreasury(msg.sender);
        _;
    }

    modifier onlyTreasuryFor(address _account) virtual {
        diamond.isTreasury(_account);
        _;
    }

    function hasRole(bytes32 _role, address _account) public view virtual returns (bool) {
        return diamond.hasRole(_role, _account);
    }

    function checkRole(bytes32 _role, address _account) public view virtual {
        diamond.checkRole(_role, _account);
    }

    function checkRole(bytes32 _role) public view virtual {
        diamond.checkRole(_role, msg.sender);
    }

    function isDiamond(address _account) external view virtual returns (bool) {
        return diamond.isDiamond(_account);
    }

    function isAdmin(address _account) external view virtual returns (bool) {
        return diamond.isAdmin(_account);
    }

    function isManager(address _account) external view virtual returns (bool) {
        return diamond.isManager(_account);
    }

    function isKeeper(address _account) external view virtual returns (bool) {
        return diamond.isKeeper(_account);
    }

    function isTreasury(address _account) external view virtual returns (bool) {
        return diamond.isTreasury(_account);
    }

    function admin() external view virtual returns (address) {
        return diamond.admin();
    }

    function treasury() external view virtual returns (address) {
        return diamond.treasury();
    }

    function managers() external view virtual returns (address[] memory) {
        return diamond.managers();
    }

    function keepers() external view virtual returns (address[] memory) {
        return diamond.keepers();
    }
}
