// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BTRStorage as S} from "../../libraries/BTRStorage.sol";
import {BTRErrors as Errors} from "../../libraries/BTREvents.sol";
import {VaultStorage} from "../../BTRTypes.sol";

/// @title NonReentrantFacet
/// @notice Abstract contract that provides reentrancy protection
abstract contract NonReentrantFacet {
    /// @notice Prevents reentrancy attacks
    modifier nonReentrant() {
        VaultStorage storage vs = S.vault();
        // Check if we're already in a reentrant call
        if (vs.reentrancyStatus == 1) revert Errors.ReentrantCall();
        
        // Mark as entered
        vs.reentrancyStatus = 1;
        
        // Execute the function
        _;
        
        // Mark as not entered
        vs.reentrancyStatus = 0;
    }
} 