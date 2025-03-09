// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {BTRErrors as Errors, BTREvents as Events} from "./BTREvents.sol";

/// @title LibRescuable
/// @notice Library for token rescue functionality
/// @dev Shared logic for rescuing tokens accidentally sent to contract
library LibRescuable {
    using SafeERC20 for IERC20Metadata;

    /*═══════════════════════════════════════════════════════════════╗
    ║                              TYPES                             ║
    ╚═══════════════════════════════════════════════════════════════*/

    struct RescueRequest {
        uint64 timestamp;
        address receiver;
    }

    struct RescuableStorage {
        mapping(address => RescueRequest) rescueRequests;
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                           CONSTANTS                            ║
    ╚═══════════════════════════════════════════════════════════════*/

    uint64 public constant RESCUE_TIMELOCK = 2 days;
    uint64 public constant RESCUE_VALIDITY = 7 days;

    // Diamond storage pattern - unique storage slot for rescue data
    bytes32 private constant RESCUABLE_STORAGE_POSITION = keccak256("btr.vault.rescue.storage");

    /*═══════════════════════════════════════════════════════════════╗
    ║                             STORAGE                            ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @dev Get the RescuableStorage struct from diamond storage
    function rescuableStorage() internal pure returns (RescuableStorage storage rs) {
        bytes32 position = RESCUABLE_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                             VIEWS                              ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Get the rescue request for a specific token
    /// @param token Token address - use address(1) for native tokens (ETH)
    /// @return receiver Recipient address for the rescue
    /// @return timestamp When the rescue was requested
    /// @return status 0=none, 1=locked, 2=unlocked, 3=expired
    function getRescueRequest(address token) internal view returns (
        address receiver,
        uint64 timestamp,
        uint8 status
    ) {
        RescueRequest memory req = rescuableStorage().rescueRequests[token];
        
        receiver = req.receiver;
        timestamp = req.timestamp;
        
        if (req.timestamp == 0) {
            status = 0; // No rescue request
        } else if (block.timestamp < (req.timestamp + RESCUE_TIMELOCK)) {
            status = 1; // Locked
        } else if (block.timestamp <= (req.timestamp + RESCUE_TIMELOCK + RESCUE_VALIDITY)) {
            status = 2; // Unlocked and valid
        } else {
            status = 3; // Expired
        }
    }

    /// @notice Check if a rescue request is currently locked
    /// @param token Token to check
    /// @return Whether the rescue request is locked
    function isRescueLocked(address token) internal view returns (bool) {
        RescueRequest memory req = rescuableStorage().rescueRequests[token];
        return req.timestamp != 0 && block.timestamp < (req.timestamp + RESCUE_TIMELOCK);
    }

    /// @notice Check if a rescue request has expired
    /// @param token Token to check
    /// @return Whether the rescue request has expired
    function isRescueExpired(address token) internal view returns (bool) {
        RescueRequest memory req = rescuableStorage().rescueRequests[token];
        return req.timestamp != 0 && block.timestamp > (req.timestamp + RESCUE_TIMELOCK + RESCUE_VALIDITY);
    }

    /// @notice Check if a rescue request is unlocked and valid
    /// @param token Token to check
    /// @return Whether the rescue request is unlocked and valid
    function isRescueUnlocked(address token) internal view returns (bool) {
        RescueRequest memory req = rescuableStorage().rescueRequests[token];
        uint256 expiryTime = req.timestamp + RESCUE_TIMELOCK + RESCUE_VALIDITY;
        return req.timestamp != 0 && 
               block.timestamp >= (req.timestamp + RESCUE_TIMELOCK) && 
               block.timestamp <= expiryTime;
    }

    /*═══════════════════════════════════════════════════════════════╗
    ║                       RESCUE FUNCTIONS                         ║
    ╚═══════════════════════════════════════════════════════════════*/

    /// @notice Request a rescue for a specific token
    /// @param token Token to be rescued - use address(1) for native tokens (ETH)
    function requestRescue(address token) internal {
        // Validate token
        if (token == address(0)) {
            revert Errors.RescueInvalidToken();
        }
        
        // Get the storage for this rescue request
        RescueRequest storage req = rescuableStorage().rescueRequests[token];
        
        // Ensure there's no active unlocked rescue request
        if (req.timestamp != 0) {
            uint256 unlockTime = req.timestamp + RESCUE_TIMELOCK;
            uint256 expiryTime = unlockTime + RESCUE_VALIDITY;
            
            if (block.timestamp >= unlockTime && block.timestamp <= expiryTime) {
                revert Errors.RescueInProgress();
            }
        }
        
        // Set the new rescue request
        req.receiver = msg.sender;
        req.timestamp = uint64(block.timestamp);
        
        emit Events.RescueRequested(token, msg.sender, uint64(block.timestamp));
    }

    /// @notice Execute a rescue for a specific token
    /// @param token Token to be rescued - use address(1) for native tokens (ETH)
    function executeRescue(address token) internal {
        // Get the storage for this rescue request
        RescueRequest storage req = rescuableStorage().rescueRequests[token];
        
        // Ensure the rescue request exists
        if (req.timestamp == 0) {
            revert Errors.RescueNotRequested();
        }
        
        // Check if the rescue is unlocked and valid
        uint256 unlockTime = req.timestamp + RESCUE_TIMELOCK;
        uint256 expiryTime = unlockTime + RESCUE_VALIDITY;
        
        if (block.timestamp < unlockTime) {
            revert Errors.RescueStillLocked(); // Still locked
        }
        
        if (block.timestamp > expiryTime) {
            revert Errors.RescueExpired(); // Expired
        }
        
        // Store details before deletion
        address receiver = req.receiver;
        
        // Clear the rescue request first to prevent reentrancy
        delete rescuableStorage().rescueRequests[token];
        
        // Execute the rescue
        uint256 amount;
        if (token == address(1)) {
            // Native token (ETH)
            amount = address(this).balance;
            (bool success, ) = payable(receiver).call{value: amount}("");
            if (!success) {
                revert Errors.RescueTransferFailed();
            }
        } else {
            // ERC20 token
            amount = IERC20Metadata(token).balanceOf(address(this));
            IERC20Metadata(token).safeTransfer(receiver, amount);
        }
        
        emit Events.RescueExecuted(token, receiver, amount);
    }

    /// @notice Cancel a pending rescue request
    /// @param token Token for which to cancel the rescue request
    /// @param caller The address attempting to cancel
    function cancelRescue(address token, address caller) internal {
        RescueRequest storage req = rescuableStorage().rescueRequests[token];
        
        // No rescue to cancel
        if (req.timestamp == 0) {
            revert Errors.RescueNotRequested();
        }
        
        // Check permissions
        bool isAdmin = LibAccessControl.hasRole(LibAccessControl.DEFAULT_ADMIN_ROLE, caller);
        bool isRequester = (req.receiver == caller);
        
        if (!isAdmin && !isRequester) {
            revert Errors.RestrictedAccess();
        }
        
        // Clear the rescue request
        delete rescuableStorage().rescueRequests[token];
        
        emit Events.RescueCancelled(token, caller);
    }
} 