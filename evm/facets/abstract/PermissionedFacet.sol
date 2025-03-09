// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibAccessControl} from "../../libraries/LibAccessControl.sol";

/// @title PermissionedFacet
/// @notice Abstract contract that provides role-based access control modifiers
abstract contract PermissionedFacet {
    /// @notice Restricts function access to users with admin role
    modifier onlyAdmin() {
        LibAccessControl.ADMIN_ROLE.checkRole();
        _;
    }

    /// @notice Restricts function access to users with manager role
    modifier onlyManager() {
        LibAccessControl.MANAGER_ROLE.checkRole();
        _;
    }

    /// @notice Restricts function access to users with keeper role
    modifier onlyKeeper() {
        LibAccessControl.KEEPER_ROLE.checkRole();
        _;
    }

    /// @notice Restricts function access to users with treasury role
    modifier onlyTreasury() {
        LibAccessControl.TREASURY_ROLE.checkRole();
        _;
    }
} 