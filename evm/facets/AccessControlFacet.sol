// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {BTRStorage as S} from "../libraries/BTRStorage.sol";
import {BTRErrors as Errors, BTREvents as Events} from "../libraries/BTREvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {AccessControlStorage, PendingAcceptance} from "../BTRTypes.sol";

/// @title AccessControlFacet
/// @notice Role-based access control facet for BTR contract
/// @dev Inspired by Astrolab's AccessController and OZ's AccessControlEnumerable
/// Also implements ERC173 for ownership backwards compatibility
contract AccessControlFacet is IERC173 {
  using EnumerableSet for EnumerableSet.AddressSet;

  /*═══════════════════════════════════════════════════════════════╗
  ║                           CONSTANTS                            ║
  ╚═══════════════════════════════════════════════════════════════*/

  uint256 public constant MIN_GRANT_DELAY = 1 days;
  uint256 public constant MAX_GRANT_DELAY = 30 days;
  uint256 public constant MIN_ACCEPT_WINDOW = 1 days;
  uint256 public constant MAX_ACCEPT_WINDOW = 30 days;

  /// @dev Predefined roles
  bytes32 public constant ADMIN_ROLE = LibAccessControl.ADMIN_ROLE;
  bytes32 public constant MANAGER_ROLE = LibAccessControl.MANAGER_ROLE;
  bytes32 public constant KEEPER_ROLE = LibAccessControl.KEEPER_ROLE;
  bytes32 public constant DEFAULT_ADMIN_ROLE = LibAccessControl.DEFAULT_ADMIN_ROLE;

  /*═══════════════════════════════════════════════════════════════╗
  ║                           MODIFIERS                            ║
  ╚═══════════════════════════════════════════════════════════════*/

  /// @notice Checks if the caller has a role
  modifier onlyRole(bytes32 role) {
    LibAccessControl.checkRole(role);
    _;
  }

  /*═══════════════════════════════════════════════════════════════╗
  ║                      ERC-173 COMPLIANCE                        ║
  ╚═══════════════════════════════════════════════════════════════*/

  /// @notice Returns the address of the owner (ERC-173)
  /// @return owner_ of the contract (the admin role holder)
  function owner() external view override returns (address owner_) {
    // Get the first address with the admin role
    address[] memory admins = LibAccessControl.getRoleMembers(ADMIN_ROLE);
    
    if (admins.length > 0) {
      return admins[0];
    }

    // If no ADMIN_ROLE is set, return zero address
    return address(0);
  }

  /// @notice Transfers ownership of the contract to a new address (ERC-173)
  /// @param _newOwner The address to transfer ownership to
  function transferOwnership(address _newOwner) external override onlyRole(ADMIN_ROLE) {
    // Require non-zero address
    if (_newOwner == address(0)) {
        revert Errors.ZeroAddress();
    }
    
    // Set up pending acceptance for admin role (this is the primary ownership mechanism)
    LibAccessControl.createRoleAcceptance(ADMIN_ROLE, _newOwner, msg.sender);
    
    // Emit ownership transfer event
    emit Events.OwnershipTransferred(msg.sender, _newOwner);
  }

  /*═══════════════════════════════════════════════════════════════╗
  ║                             VIEWS                              ║
  ╚═══════════════════════════════════════════════════════════════*/

  /// @notice Checks if `account` has `role`
  /// @param role The role to check
  /// @param account The account to check
  /// @return bool Whether the account has the role
  function hasRole(bytes32 role, address account) public view returns (bool) {
    return LibAccessControl.hasRole(role, account);
  }

  /// @notice Checks if `msg.sender` has `role`
  /// @param role The role to check
  function checkRole(bytes32 role) public view {
    LibAccessControl.checkRole(role);
  }

  /// @notice Checks if `account` has `role`
  /// @param role The role to check
  /// @param account The account to check
  function checkRole(bytes32 role, address account) public view {
    LibAccessControl.checkRole(role, account);
  }

  /// @notice Gets the admin role for a specific role
  /// @param role The role to get the admin for
  /// @return bytes32 The admin role
  function getRoleAdmin(bytes32 role) public view returns (bytes32) {
    return LibAccessControl.getRoleAdmin(role);
  }

  /// @notice Gets all members of a role
  /// @param role The role to get members for
  /// @return Array of addresses with the role
  function getMembers(bytes32 role) public view returns (address[] memory) {
    return LibAccessControl.getRoleMembers(role);
  }

  /// @notice Get current grant delay and accept window
  /// @return grantDelay Current grant delay
  /// @return acceptWindow Current accept window
  function getTimelockConfig() external view returns (uint256 grantDelay, uint256 acceptWindow) {
    AccessControlStorage storage acs = S.accessControl();
    return (acs.grantDelay, acs.acceptWindow);
  }

  /// @notice Checks acceptance state for a pending role change
  /// @param acceptance The acceptance data to check
  /// @param role The role to check against
  function checkRoleAcceptance(
    PendingAcceptance memory acceptance,
    bytes32 role
  ) public view {
    // Make sure the role accepted is the same as the pending one
    if (acceptance.role != role) {
      revert Errors.Unauthorized();
    }
    
    // Grant the keeper role instantly (no attack surface here)
    if (acceptance.role == KEEPER_ROLE) return;
    
    (uint256 grantDelay, uint256 acceptWindow) = LibAccessControl.getTimelockConfig();
    
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

  /// @notice Returns the pending role details for an account
  /// @param role The role to check
  /// @param account The account to check
  /// @return pendingRole The pending role
  /// @return replacing The address being replaced (for ADMIN)
  /// @return timestamp When the role grant was initiated
  function getPendingAcceptance(bytes32 role, address account) 
    external 
    view 
    returns (
      bytes32 pendingRole,
      address replacing,
      uint64 timestamp
    )
  {
    PendingAcceptance memory acceptance = LibAccessControl.getPendingAcceptance(account);
    
    return (
      acceptance.role,
      acceptance.replacing,
      acceptance.timestamp
    );
  }

  /// @return Address of the admin
  function admin() external view returns (address) {
    address[] memory admins = getMembers(ADMIN_ROLE);
    return admins.length > 0 ? admins[0] : address(0);
  }

  /// @return Array of MANAGER addresses
  function getManagers() external view returns (address[] memory) {
    return getMembers(MANAGER_ROLE);
  }

  /// @return Array of KEEPER addresses
  function getKeepers() external view returns (address[] memory) {
    return getMembers(KEEPER_ROLE);
  }

  /// @notice Checks if account is an ADMIN
  /// @param account The account to check
  /// @return bool Whether the account is an admin
  function isAdmin(address account) external view returns (bool) {
    return hasRole(ADMIN_ROLE, account);
  }

  /// @notice Checks if account is a MANAGER
  /// @param account The account to check
  /// @return bool Whether the account is a manager
  function isManager(address account) external view returns (bool) {
    return hasRole(MANAGER_ROLE, account);
  }

  /// @notice Checks if account is a KEEPER
  /// @param account The account to check
  /// @return bool Whether the account is a keeper
  function isKeeper(address account) external view returns (bool) {
    return hasRole(KEEPER_ROLE, account);
  }

  /// @notice Checks if account is a TREASURY
  /// @param account The account to check
  /// @return bool Whether the account is a treasury
  function isTreasury(address account) external view returns (bool) {
    return hasRole(TREASURY_ROLE, account);
  }

  /*═══════════════════════════════════════════════════════════════╗
  ║                          INITIALIZE                            ║
  ╚═══════════════════════════════════════════════════════════════*/

  /// @notice Initialize the access control with default roles
  /// @param initialAdmin The initial admin address
  function initialize(address initialAdmin) external {
    // Only admin can initialize
    LibAccessControl.checkRole(LibAccessControl.DEFAULT_ADMIN_ROLE);
    
    // Initialize access control
    LibAccessControl.initializeAccessControl(initialAdmin);
  }

  /*═══════════════════════════════════════════════════════════════╗
  ║                             LOGIC                              ║
  ╚═══════════════════════════════════════════════════════════════*/

  /// @notice Sets admin role for a specific role
  /// @param role The role to set the admin for
  /// @param adminRole The admin role to set
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(ADMIN_ROLE) {
    LibAccessControl.setRoleAdmin(role, adminRole);
  }

  /// @notice Update timelock configuration
  /// @param grantDelay New grant delay (in seconds)
  /// @param acceptWindow New accept window (in seconds)
  function setTimelockConfig(uint256 grantDelay, uint256 acceptWindow) external onlyRole(ADMIN_ROLE) {
    if (grantDelay < MIN_GRANT_DELAY || grantDelay > MAX_GRANT_DELAY) {
        revert Errors.InvalidGrantDelay(grantDelay, MIN_GRANT_DELAY, MAX_GRANT_DELAY);
    }
    if (acceptWindow < MIN_ACCEPT_WINDOW || acceptWindow > MAX_ACCEPT_WINDOW) {
        revert Errors.InvalidAcceptWindow(acceptWindow, MIN_ACCEPT_WINDOW, MAX_ACCEPT_WINDOW);
    }
    LibAccessControl.setTimelockConfig(grantDelay, acceptWindow);
  }

  /// @notice Grants role to account
  /// @param role The role to grant
  /// @param account The account to grant the role to
  function grantRole(
    bytes32 role,
    address account
  ) external onlyRole(getRoleAdmin(role)) {
    if (hasRole(role, account)) {
        revert Errors.RoleAlreadyAssigned();
    }
    LibAccessControl.createRoleAcceptance(role, account, msg.sender);
  }

  /// @notice Revokes role from account
  /// @param role The role to revoke
  /// @param account The account to revoke from
  function revokeRole(
    bytes32 role,
    address account
  ) external onlyRole(getRoleAdmin(role)) {
    LibAccessControl.revokeRole(role, account);
  }

  /// @notice Renounces a role (self-revocation)
  /// @param role The role to renounce
  function renounceRole(bytes32 role) external {
    LibAccessControl.revokeRole(role, msg.sender);
  }

  /// @notice Accepts a pending role grant
  /// @param role The role to accept
  function acceptRole(bytes32 role) external {
    LibAccessControl.processRoleAcceptance(role, msg.sender);
  }

  /// @notice Cancel a pending role grant
  /// @param role The role to cancel
  /// @param account The account to cancel for
  function cancelRoleGrant(bytes32 role, address account) external onlyRole(getRoleAdmin(role)) {
    LibAccessControl.cancelRoleAcceptance(account);
  }
}
