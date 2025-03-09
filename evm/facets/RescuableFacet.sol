// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibRescuable} from "../libraries/LibRescuable.sol";
import {BTRErrors as Errors, BTREvents as Events} from "../libraries/BTREvents.sol";

/// @title Rescuable Facet
/// @notice Provides external interface for token rescue functionality
/// @dev Uses LibRescuable for the core logic
contract RescuableFacet {
    /*═══════════════════════════════════════════════════════════════╗
    ║                           CONSTANTS                            ║
    ╚═══════════════════════════════════════════════════════════════*/

    uint64 public constant RESCUE_TIMELOCK = LibRescuable.RESCUE_TIMELOCK;
    uint64 public constant RESCUE_VALIDITY = LibRescuable.RESCUE_VALIDITY;

    /*═══════════════════════════════════════════════════════════════╗
    ║                             VIEWS                              ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Get the rescue request for a specific token
    /// @param token Token address - use address(1) for native tokens (ETH)
    /// @return receiver Recipient address for the rescue
    /// @return timestamp When the rescue was requested
    /// @return status 0=none, 1=locked, 2=unlocked, 3=expired
    function getRescueRequest(address token) external view returns (
        address receiver,
        uint64 timestamp,
        uint8 status
    ) {
        return LibRescuable.getRescueRequest(token);
    }

    /// @notice Check if a rescue request is currently locked
    /// @param token Token to check
    /// @return Whether the rescue request is locked
    function isRescueLocked(address token) external view returns (bool) {
        return LibRescuable.isRescueLocked(token);
    }

    /// @notice Check if a rescue request has expired
    /// @param token Token to check
    /// @return Whether the rescue request has expired
    function isRescueExpired(address token) external view returns (bool) {
        return LibRescuable.isRescueExpired(token);
    }

    /// @notice Check if a rescue request is unlocked and valid
    /// @param token Token to check
    /// @return Whether the rescue request is unlocked and valid
    function isRescueUnlocked(address token) external view returns (bool) {
        return LibRescuable.isRescueUnlocked(token);
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                       RESCUE FUNCTIONS                         ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Request a rescue for a specific token
    /// @param token Token to be rescued - use address(1) for native tokens (ETH)
    function requestRescue(address token) external {
        // Only admin can request rescues
        LibAccessControl.checkRole(LibAccessControl.DEFAULT_ADMIN_ROLE);
        
        LibRescuable.requestRescue(token);
    }

    /// @notice Execute a rescue for a specific token
    /// @param token Token to be rescued - use address(1) for native tokens (ETH)
    function executeRescue(address token) external {
        // Only managers can execute rescues
        LibAccessControl.checkRole(LibAccessControl.MANAGER_ROLE);
        
        LibRescuable.executeRescue(token);
    }

    /// @notice Cancel a pending rescue request
    /// @param token Token for which to cancel the rescue request
    function cancelRescue(address token) external {
        LibRescuable.cancelRescue(token, msg.sender);
    }
} 