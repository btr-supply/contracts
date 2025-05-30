// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {
    AccessControl,
    RoleData,
    PendingAcceptance,
    ErrorType,
    TokenType,
    Rescue,
    Restrictions,
    AccountStatus,
    ALMVault
} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibRescue} from "@libraries/LibRescue.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Access Control Library - Role-based access control logic
 * @copyright 2025
 * @notice Provides internal functions for checking roles and permissions
 * @dev Helper library for AccessControlFacet and Permissioned contracts
 * @author BTR Team
 */

library LibAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using U for uint32;

    // --- CONSTANTS ---

    uint256 public constant DEFAULT_GRANT_DELAY = 2 days;
    uint256 public constant DEFAULT_ACCEPT_WINDOW = 7 days;
    uint256 public constant MIN_GRANT_DELAY = 1 days;
    uint256 public constant MAX_GRANT_DELAY = 30 days;
    uint256 public constant MIN_ACCEPT_WINDOW = 1 days;
    uint256 public constant MAX_ACCEPT_WINDOW = 30 days;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    // --- INITIALIZATION ---

    function initialize(AccessControl storage _ac, address _admin, address _treasury) internal {
        if (_admin == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (admin(_ac) != address(0)) {
            revert Errors.AlreadyInitialized();
        }

        _ac.grantDelay = DEFAULT_GRANT_DELAY;
        _ac.acceptanceTtl = DEFAULT_ACCEPT_WINDOW;
        grantRole(_ac, ADMIN_ROLE, _admin);
        grantRole(_ac, MANAGER_ROLE, _admin);
        if (_treasury != address(0)) {
            grantRole(_ac, TREASURY_ROLE, _treasury);
        }
        setRoleAdmin(_ac, ADMIN_ROLE, ADMIN_ROLE);
        setRoleAdmin(_ac, MANAGER_ROLE, ADMIN_ROLE);
        setRoleAdmin(_ac, KEEPER_ROLE, ADMIN_ROLE);
        setRoleAdmin(_ac, TREASURY_ROLE, ADMIN_ROLE);
        emit Events.TimelockConfigUpdated(DEFAULT_GRANT_DELAY, DEFAULT_ACCEPT_WINDOW);
    }

    // --- VIEWS ---

    function timelockConfig(AccessControl storage _ac)
        internal
        view
        returns (uint256 grantDelay, uint256 acceptanceTtl)
    {
        return (_ac.grantDelay, _ac.acceptanceTtl);
    }

    function getPendingAcceptance(AccessControl storage _ac, address _account)
        internal
        view
        returns (PendingAcceptance memory)
    {
        return _ac.pendingAcceptance[_account];
    }

    function getRoleAdmin(AccessControl storage _ac, bytes32 _role) private view returns (bytes32) {
        return _ac.roles[_role].adminRole;
    }

    function members(AccessControl storage _ac, bytes32 _role) internal view returns (address[] memory) {
        RoleData storage role = _ac.roles[_role];
        uint256 length = role.members.length();
        address[] memory result = new address[](length);
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                result[i] = role.members.at(i);
            }
        }
        return result;
    }

    function member0(AccessControl storage _ac, bytes32 _role) internal view returns (address) {
        address[] memory m = members(_ac, _role);
        return m.length > 0 ? m[0] : address(0);
    }

    function admin(AccessControl storage _ac) internal view returns (address) {
        return member0(_ac, ADMIN_ROLE);
    }

    function treasury(AccessControl storage _ac) internal view returns (address) {
        return member0(_ac, TREASURY_ROLE);
    }

    function managers(AccessControl storage _ac) internal view returns (address[] memory) {
        return members(_ac, MANAGER_ROLE);
    }

    function keepers(AccessControl storage _ac) internal view returns (address[] memory) {
        return members(_ac, KEEPER_ROLE);
    }

    function checkRole(AccessControl storage _ac, bytes32 _role, address _account) internal view {
        if (!hasRole(_ac, _role, _account)) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }
    }

    function checkRole(AccessControl storage _ac, bytes32 _role) internal view {
        checkRole(_ac, _role, msg.sender);
    }

    function checkRoleAdmin(AccessControl storage _ac, bytes32 _role, address _account) internal view {
        checkRole(_ac, getRoleAdmin(_ac, _role), _account);
    }

    function checkRoleAdmin(AccessControl storage _ac, bytes32 _role) internal view {
        checkRoleAdmin(_ac, _role, msg.sender);
    }

    function checkRoleAcceptance(AccessControl storage _ac, PendingAcceptance memory _acceptance, bytes32 _role)
        internal
        view
    {
        if (_acceptance.role != _role) {
            revert Errors.Unauthorized(ErrorType.ROLE);
        }
        if (_acceptance.role == KEEPER_ROLE) return;

        (uint256 grantDelay, uint256 acceptanceTtl) = timelockConfig(_ac);

        if (block.timestamp > (_acceptance.timestamp + grantDelay + acceptanceTtl)) {
            revert Errors.Expired(ErrorType.ACCEPTANCE);
        }
        if (block.timestamp < (_acceptance.timestamp + grantDelay)) {
            revert Errors.Locked();
        }
    }

    // --- ROLE MODIFICATIONS ---

    function setRoleAdmin(AccessControl storage _ac, bytes32 _role, bytes32 _adminRole) internal {
        if (!hasRole(_ac, ADMIN_ROLE, msg.sender)) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }
        if (_role == ADMIN_ROLE) {
            revert Errors.Unauthorized(ErrorType.ADMIN);
        }

        RoleData storage roleData = _ac.roles[_role];
        bytes32 previousAdminRole = roleData.adminRole;
        roleData.adminRole = _adminRole;

        emit Events.RoleAdminUpdated(_role, previousAdminRole, _adminRole);
    }

    function setTimelockConfig(AccessControl storage _ac, uint256 _grantDelay, uint256 _acceptanceTtl) internal {
        if (!hasRole(_ac, ADMIN_ROLE, msg.sender)) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }
        if (
            _grantDelay < MIN_GRANT_DELAY || _grantDelay > MAX_GRANT_DELAY || _acceptanceTtl < MIN_ACCEPT_WINDOW
                || _acceptanceTtl > MAX_ACCEPT_WINDOW
        ) {
            revert Errors.OutOfRange(_grantDelay, MIN_GRANT_DELAY, MAX_GRANT_DELAY);
        }

        _ac.grantDelay = _grantDelay;
        _ac.acceptanceTtl = _acceptanceTtl;

        emit Events.TimelockConfigUpdated(_grantDelay, _acceptanceTtl);
    }

    function safeGrantRole(AccessControl storage _ac, bytes32 _role, address _account, address _replacing) internal {
        if (_account == address(0)) {
            revert Errors.ZeroAddress();
        }
        bytes32 roleAdmin = getRoleAdmin(_ac, _role);
        if (!hasRole(_ac, roleAdmin, msg.sender)) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }

        if (hasRole(_ac, _role, _account)) {
            revert Errors.AlreadyExists(ErrorType.ROLE);
        }

        bytes32 adminRole = getRoleAdmin(_ac, _role);
        if (adminRole == bytes32(0) && _role != ADMIN_ROLE) {
            revert Errors.NotFound(ErrorType.ROLE);
        }

        if (_replacing == _account) {
            revert Errors.InvalidParameter();
        }

        if (_role == KEEPER_ROLE || member0(_ac, _role) == address(0)) {
            grantRole(_ac, _role, _account);
            return;
        }

        _ac.pendingAcceptance[_account] =
            PendingAcceptance({replacing: _replacing, timestamp: uint64(block.timestamp), role: _role});

        emit Events.RoleAcceptanceCreated(_role, _account, _replacing);
    }

    function acceptRole(AccessControl storage _ac, Rescue storage _res, address _account) internal {
        PendingAcceptance memory acceptance = _ac.pendingAcceptance[_account];
        if (acceptance.role == bytes32(0)) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }

        bytes32 _role = acceptance.role;
        grantRole(_ac, acceptance.role, _account);

        address replacing = acceptance.replacing;
        if (replacing != address(0)) {
            if (_role == ADMIN_ROLE) {
                LibRescue.cancelRescueAll(_res, replacing);
            }
            revokeRole(_ac, _role, replacing);
        }

        delete _ac.pendingAcceptance[_account];
    }

    function cancelRoleGrant(AccessControl storage _ac, address _account) internal {
        PendingAcceptance memory acceptance = _ac.pendingAcceptance[_account];

        if (
            !hasRole(_ac, ADMIN_ROLE, msg.sender) && !hasRole(_ac, getRoleAdmin(_ac, acceptance.role), msg.sender)
                && msg.sender != _account
        ) {
            revert Errors.Unauthorized(ErrorType.ACCESS);
        }

        emit Events.RoleAcceptanceCreated(acceptance.role, address(0), _account);
        delete _ac.pendingAcceptance[_account];
    }

    function revokeRole(AccessControl storage _ac, bytes32 _role, address _account) internal {
        if (_account != msg.sender) {
            bytes32 roleAdmin = getRoleAdmin(_ac, _role);
            if (!hasRole(_ac, roleAdmin, msg.sender) && !hasRole(_ac, ADMIN_ROLE, msg.sender)) {
                revert Errors.Unauthorized(ErrorType.ACCESS);
            }
        }
        RoleData storage roleData = _ac.roles[_role];

        if (_role == ADMIN_ROLE && roleData.members.length() == 1) {
            revert Errors.Unauthorized(ErrorType.ADMIN);
        }

        if (!hasRole(_ac, _role, _account)) {
            revert Errors.NotFound(ErrorType.ROLE);
        }

        roleData.members.remove(_account);
        emit Events.RoleRevoked(_role, _account, msg.sender);

        if (_role == ADMIN_ROLE) {
            address newOwner = roleData.members.length() > 0 ? roleData.members.at(0) : address(0);
            emit Events.OwnershipTransferred(_account, newOwner);
        }
    }

    function revokeAll(AccessControl storage _ac, bytes32 _role) internal {
        checkRoleAdmin(_ac, _role);
        address[] memory _members = members(_ac, _role);
        unchecked {
            for (uint256 i = 0; i < _members.length; i++) {
                revokeRole(_ac, _role, _members[i]);
            }
        }
    }

    function revokeAllManagers(AccessControl storage _ac) internal {
        revokeAll(_ac, MANAGER_ROLE);
    }

    function revokeAllKeepers(AccessControl storage _ac) internal {
        revokeAll(_ac, KEEPER_ROLE);
    }

    function hasRole(AccessControl storage _ac, bytes32 _role, address _account) internal view returns (bool) {
        return _ac.roles[_role].members.contains(_account);
    }

    function grantRole(AccessControl storage _ac, bytes32 _role, address _account) private {
        if (hasRole(_ac, _role, _account)) {
            return;
        }

        RoleData storage roleData = _ac.roles[_role];
        roleData.members.add(_account);

        emit Events.RoleGranted(_role, _account, msg.sender);

        if (_role == ADMIN_ROLE) {
            emit Events.OwnershipTransferred(msg.sender, _account);
        }
    }

    function isAlmMinterUnrestricted(Restrictions storage _rs, uint32 _vid, address _account)
        internal
        view
        returns (bool)
    {
        return _vid.vault().mintRestricted ? isWhitelisted(_rs, _account) : !isBlacklisted(_rs, _account);
    }

    // --- CHECKS/ENSURE OR REVERT ---

    function checkNotBlacklisted(Restrictions storage _rs, address _account) internal view {
        if (_rs.accountStatus[_account] == AccountStatus.BLACKLISTED) {
            revert Errors.Unauthorized(ErrorType.ADDRESS);
        }
    }

    function checkWhitelisted(Restrictions storage _rs, address _account) internal view {
        if (_rs.accountStatus[_account] != AccountStatus.WHITELISTED) {
            revert Errors.Unauthorized(ErrorType.ADDRESS);
        }
    }

    function checkUnlisted(Restrictions storage _rs, address _account) internal view {
        if (_rs.accountStatus[_account] != AccountStatus.NONE) {
            revert Errors.Unauthorized(ErrorType.ADDRESS);
        }
    }

    function checkAlmMinterUnrestricted(Restrictions storage _rs, uint32 _vid, address _account) internal view {
        if (!isAlmMinterUnrestricted(_rs, _vid, _account)) revert Errors.Unauthorized(ErrorType.ADDRESS);
    }

    // --- ACCOUNT STATUS ---

    function accountStatus(Restrictions storage _rs, address _account) internal view returns (AccountStatus) {
        return _rs.accountStatus[_account];
    }

    function setAccountStatus(Restrictions storage _rs, address _account, AccountStatus _status) internal {
        mapping(address => AccountStatus) storage sm = _rs.accountStatus;
        AccountStatus prev = sm[_account];
        sm[_account] = _status;
        emit Events.AccountStatusUpdated(_account, prev, _status);
    }

    function setAccountStatusBatch(Restrictions storage _rs, address[] memory _accounts, AccountStatus _status)
        internal
    {
        uint256 len = _accounts.length;
        unchecked {
            for (uint256 i = 0; i < len; i++) {
                setAccountStatus(_rs, _accounts[i], _status);
            }
        }
    }

    // --- WHITELISTED/BLACKLISTED ---

    function addToWhitelist(Restrictions storage _rs, address _account) internal {
        setAccountStatus(_rs, _account, AccountStatus.WHITELISTED);
    }

    function removeFromList(Restrictions storage _rs, address _account) internal {
        setAccountStatus(_rs, _account, AccountStatus.NONE);
    }

    function addToBlacklist(Restrictions storage _rs, address _account) internal {
        setAccountStatus(_rs, _account, AccountStatus.BLACKLISTED);
    }

    function isWhitelisted(Restrictions storage _rs, address _account) internal view returns (bool) {
        return accountStatus(_rs, _account) == AccountStatus.WHITELISTED;
    }

    function isBlacklisted(Restrictions storage _rs, address _account) internal view returns (bool) {
        return accountStatus(_rs, _account) == AccountStatus.BLACKLISTED;
    }

    function addToListBatch(Restrictions storage _rs, address[] memory _accounts, AccountStatus _status) internal {
        for (uint256 i = 0; i < _accounts.length;) {
            setAccountStatus(_rs, _accounts[i], _status);
            unchecked {
                ++i;
            }
        }
    }

    function removeFromListBatch(Restrictions storage _rs, address[] memory _accounts) internal {
        for (uint256 i = 0; i < _accounts.length;) {
            setAccountStatus(_rs, _accounts[i], AccountStatus.NONE);
            unchecked {
                ++i;
            }
        }
    }
}
