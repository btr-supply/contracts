// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {LibAccessControl} from "./libraries/LibAccessControl.sol";
import {AccessControlStorage} from "./BTRTypes.sol";

/// @title BTRVaultInit
/// @dev Diamond initializer contract for setting up a new BTR vault
contract BTRVaultInit {
  /// @notice Initializes a BTR vault diamond with access control
  /// @param _managers Array of manager addresses
  /// @param _keepers Array of keeper addresses
  function init(address[] calldata _managers, address[] calldata _keepers) external {
    // Initialize access control roles
    AccessControlStorage storage acs = LibAccessControl.accessControlStorage();
    
    // Set up default role admins
    acs.roles[LibAccessControl.MANAGER_ROLE].adminRole = LibAccessControl.DEFAULT_ADMIN_ROLE;
    acs.roles[LibAccessControl.KEEPER_ROLE].adminRole = LibAccessControl.DEFAULT_ADMIN_ROLE;
    
    // Set up managers
    for (uint256 i = 0; i < _managers.length; i++) {
      acs.roles[LibAccessControl.MANAGER_ROLE].members[_managers[i]] = true;
    }
    
    // Set up keepers
    for (uint256 i = 0; i < _keepers.length; i++) {
      acs.roles[LibAccessControl.KEEPER_ROLE].members[_keepers[i]] = true;
    }
    
    // Set default timelock config
    acs.grantDelay = LibAccessControl.DEFAULT_GRANT_DELAY;
    acs.acceptWindow = LibAccessControl.DEFAULT_ACCEPT_WINDOW;
  }
} 