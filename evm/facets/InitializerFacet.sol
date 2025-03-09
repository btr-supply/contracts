// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {BTRStorage as S} from "../libraries/BTRStorage.sol";
import {BTRErrors as Errors, BTREvents as Events} from "../libraries/BTREvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControlStorage} from "../BTRTypes.sol";

contract InitializerFacet {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct InitArgs {
        bytes32[] roles;
        bytes32[] roleAdmins;
        address[] managers;
        address[] keepers;
    }

    /// @notice Initialize the diamond with roles and admins
    /// @param _initArgs Initialization arguments
    function init(InitArgs calldata _initArgs) external {
        AccessControlStorage storage acs = S.accessControl();
        
        // Ensure DEFAULT_ADMIN_ROLE and ADMIN_ROLE have the same admin in constructor
        if (acs.roles[LibAccessControl.ADMIN_ROLE].adminRole == bytes32(0)) {
            acs.roles[LibAccessControl.ADMIN_ROLE].adminRole = LibAccessControl.DEFAULT_ADMIN_ROLE;
            emit Events.RoleAdminChanged(
                LibAccessControl.ADMIN_ROLE, 
                bytes32(0), 
                LibAccessControl.DEFAULT_ADMIN_ROLE
            );
        }
        
        // Set up role admins
        for (uint256 i = 0; i < _initArgs.roles.length; i++) {
            bytes32 role = _initArgs.roles[i];
            bytes32 adminRole = _initArgs.roleAdmins[i];
            
            // Set the admin role
            acs.roles[role].adminRole = adminRole;
            
            // Emit event
            emit Events.RoleAdminChanged(role, bytes32(0), adminRole);
        }
        
        // Set up default role structure if not explicitly set
        if (acs.roles[LibAccessControl.MANAGER_ROLE].adminRole == bytes32(0)) {
            acs.roles[LibAccessControl.MANAGER_ROLE].adminRole = LibAccessControl.DEFAULT_ADMIN_ROLE;
            emit Events.RoleAdminChanged(
                LibAccessControl.MANAGER_ROLE, 
                bytes32(0), 
                LibAccessControl.DEFAULT_ADMIN_ROLE
            );
        }
        
        if (acs.roles[LibAccessControl.KEEPER_ROLE].adminRole == bytes32(0)) {
            acs.roles[LibAccessControl.KEEPER_ROLE].adminRole = LibAccessControl.DEFAULT_ADMIN_ROLE;
            emit Events.RoleAdminChanged(
                LibAccessControl.KEEPER_ROLE, 
                bytes32(0), 
                LibAccessControl.DEFAULT_ADMIN_ROLE
            );
        }
        
        // Set up managers
        for (uint256 i = 0; i < _initArgs.managers.length; i++) {
            address manager = _initArgs.managers[i];
            
            // Grant manager role directly (without timelock for initialization)
            acs.roles[LibAccessControl.MANAGER_ROLE].members.add(manager);
        }
        
        // Set up keepers
        for (uint256 i = 0; i < _initArgs.keepers.length; i++) {
            address keeper = _initArgs.keepers[i];
            
            // Grant keeper role directly (without timelock for initialization)
            acs.roles[LibAccessControl.KEEPER_ROLE].members.add(keeper);
        }
        
        // Set default timelock config
        acs.grantDelay = LibAccessControl.GRANT_DELAY;
        acs.acceptWindow = LibAccessControl.ACCEPT_WINDOW;
        
        emit Events.TimelockConfigUpdated(
            LibAccessControl.GRANT_DELAY,
            LibAccessControl.ACCEPT_WINDOW
        );
    }
} 