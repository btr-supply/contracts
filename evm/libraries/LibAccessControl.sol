// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BTRStorage as S} from "./BTRStorage.sol";
import {BTRErrors as Errors, BTREvents as Events} from "./BTREvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControlStorage, RoleData, PendingAcceptance} from "../BTRTypes.sol";

/// @title LibAccessControl
/// @notice Library to manage role-based access control
library LibAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*═══════════════════════════════════════════════════════════════╗
    ║                              TYPES                             ║
    ╚═══════════════════════════════════════════════════════════════*/

    // Role-related structures are now defined in BTRTypes.sol

    /*═══════════════════════════════════════════════════════════════╗
    ║                          CONSTANTS                             ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Timelock constants for role acceptance
    /// @dev GRANT_DELAY: Time that must pass before a role can be accepted
    ///      ACCEPT_WINDOW: Time window during which a role can be accepted after the delay
    uint256 public constant GRANT_DELAY = 2 days;
    uint256 public constant ACCEPT_WINDOW = 7 days;

    /// @dev Predefined roles
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    /*═══════════════════════════════════════════════════════════════╗
    ║                       ROLE MANAGEMENT                          ║
    ╚═══════════════════════════════════════════════════════════════*/
    
    /// @notice Shorthand accessor for the access control storage
    function accessControlStorage() internal pure returns (AccessControlStorage storage) {
        return S.accessControl();
    }

    /// @notice Checks if `account` has `role`
    /// @param role The role to check
    /// @param account The account to check
    /// @return bool Whether the account has the role
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return S.accessControl().roles[role].members.contains(account);
    }

    /// @notice Checks if `msg.sender` has `role`
    /// @param role The role to check
    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    /// @notice Checks if `account` has `role`
    /// @param role The role to check
    /// @param account The account to check
    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert Errors.Unauthorized();
        }
    }

    /// @notice Gets the admin role for a specific role
    /// @param role The role to get the admin for
    /// @return bytes32 The admin role
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return S.accessControl().roles[role].adminRole;
    }

    /// @notice Gets all members of a role
    /// @param role The role to get members for
    /// @return Array of addresses with the role
    function getRoleMembers(bytes32 role) internal view returns (address[] memory) {
        AccessControlStorage storage acs = S.accessControl();
        RoleData storage roleData = acs.roles[role];
        
        uint256 length = roleData.members.length();
        address[] memory result = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = roleData.members.at(i);
        }

        return result;
    }

    /// @notice Get current grant delay and accept window
    /// @return grantDelay Current grant delay
    /// @return acceptWindow Current accept window
    function getTimelockConfig() internal view returns (uint256 grantDelay, uint256 acceptWindow) {
        AccessControlStorage storage acs = S.accessControl();
        return (acs.grantDelay, acs.acceptWindow);
    }

    /// @notice Checks acceptance state for a pending role change
    /// @param acceptance The acceptance data to check
    /// @param role The role to check against
    function checkRoleAcceptance(
        PendingAcceptance memory acceptance,
        bytes32 role
    ) internal view {
        // Make sure the role accepted is the same as the pending one
        if (acceptance.role != role) {
            revert Errors.Unauthorized();
        }
        
        // Grant the keeper role instantly (no attack surface here)
        if (acceptance.role == KEEPER_ROLE) return;
        
        (uint256 grantDelay, uint256 acceptWindow) = getTimelockConfig();
        
        // Check expiry
        if (
            block.timestamp > (acceptance.timestamp + grantDelay + acceptWindow)
        ) {
            revert Errors.AcceptanceExpired();
        }
        
        // Check timelock
        if (block.timestamp < (acceptance.timestamp + grantDelay)) {
            revert Errors.AcceptanceLocked();
        }
    }

    /// @notice Get an account's pending acceptance
    /// @param account The account to check
    /// @return The pending acceptance data
    function getPendingAcceptance(address account) internal view returns (PendingAcceptance memory) {
        return S.accessControl().pendingAcceptance[account];
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                      ROLE MODIFICATIONS                        ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Internal function to set the admin role
    /// @param role The role to set the admin for
    /// @param adminRole The admin role to set
    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        AccessControlStorage storage acs = S.accessControl();
        RoleData storage roleData = acs.roles[role];
        
        bytes32 previousAdminRole = roleData.adminRole;
        roleData.adminRole = adminRole;
        
        emit Events.RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @notice Update timelock configuration
    /// @param grantDelay New grant delay (in seconds)
    /// @param acceptWindow New accept window (in seconds)
    function setTimelockConfig(uint256 grantDelay, uint256 acceptWindow) internal {
        AccessControlStorage storage acs = S.accessControl();
        acs.grantDelay = grantDelay;
        acs.acceptWindow = acceptWindow;
        
        emit Events.TimelockConfigUpdated(grantDelay, acceptWindow);
    }

    /// @notice Create a pending role assignment
    /// @param role The role to assign
    /// @param account The account to assign the role to
    /// @param sender The address initiating the assignment
    function createRoleAcceptance(bytes32 role, address account, address sender) internal {
        if (account == address(0)) {
            revert Errors.ZeroAddress();
        }

        // No acceptance needed for keepers
        if (role == KEEPER_ROLE) {
            grantRole(role, account);
            return;
        }

        // Set up pending acceptance
        AccessControlStorage storage acs = S.accessControl();
        acs.pendingAcceptance[account] = PendingAcceptance({
            // Only get replaced if admin (managers can coexist)
            replacing: role == ADMIN_ROLE ? sender : address(0),
            timestamp: uint64(block.timestamp),
            role: role
        });
    }

    /// @notice Process a role acceptance
    /// @param role The role being accepted
    /// @param account The account accepting the role
    function processRoleAcceptance(bytes32 role, address account) internal {
        AccessControlStorage storage acs = S.accessControl();
        PendingAcceptance memory acceptance = acs.pendingAcceptance[account];
        
        checkRoleAcceptance(acceptance, role);
        
        if (acceptance.replacing != address(0)) {
            // If replacing, revoke the old role
            revokeRole(acceptance.role, acceptance.replacing);
        }
        
        grantRole(acceptance.role, account);
        delete acs.pendingAcceptance[account];
    }

    /// @notice Cancel a pending role grant
    /// @param account The account to cancel for
    function cancelRoleAcceptance(address account) internal {
        delete S.accessControl().pendingAcceptance[account];
    }

    /// @notice Grant a role to an account
    /// @param role The role to grant
    /// @param account The account to grant the role to
    function grantRole(bytes32 role, address account) internal {
        AccessControlStorage storage acs = S.accessControl();
        RoleData storage roleData = acs.roles[role];
        
        if (!roleData.members.contains(account)) {
            roleData.members.add(account);
            emit Events.RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Revoke a role from an account
    /// @param role The role to revoke
    /// @param account The account to revoke from 
    function revokeRole(bytes32 role, address account) internal {
        if (role == ADMIN_ROLE) {
            revert Errors.AdminRoleRevocation(); // Admin role can't be revoked as it would brick the contract
        }

        AccessControlStorage storage acs = S.accessControl();
        RoleData storage roleData = acs.roles[role];
        
        if (roleData.members.contains(account)) {
            roleData.members.remove(account);
            emit Events.RoleRevoked(role, account, msg.sender);
        }
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                         INITIALIZATION                         ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Initialize the access control system
    /// @param admin The initial admin address
    function initializeAccessControl(address admin) internal {
        if (admin == address(0)) {
            revert Errors.ZeroAddress();
        }

        // Check if already initialized
        if (hasRole(ADMIN_ROLE, admin)) {
            revert Errors.AccessControlAlreadyInitialized();
        }
        
        // Grant initial roles
        grantRole(ADMIN_ROLE, admin);
        grantRole(MANAGER_ROLE, admin);
        
        // Set up role admins
        setRoleAdmin(KEEPER_ROLE, ADMIN_ROLE);
        setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        setRoleAdmin(TREASURY_ROLE, ADMIN_ROLE);

        // Set default timelock settings
        AccessControlStorage storage acs = S.accessControl();
        acs.grantDelay = GRANT_DELAY;
        acs.acceptWindow = ACCEPT_WINDOW;
        
        emit Events.TimelockConfigUpdated(GRANT_DELAY, ACCEPT_WINDOW);
    }
} 