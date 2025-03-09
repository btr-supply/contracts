// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BTRStorage as S} from "../../libraries/BTRStorage.sol";
import {BTRErrors as Errors, BTREvents as Events} from "../../libraries/BTREvents.sol";
import {VaultStorage, ErrorType} from "../../BTRTypes.sol";
import {LibAccessControl} from "../../libraries/LibAccessControl.sol";

/// @title PausableFacet
/// @notice Abstract contract that provides pausable functionality
abstract contract PausableFacet {
    /// @notice Ensures function can only be called when the vault is not paused
    modifier whenNotPaused() {
        if (S.protocol().paused) revert Errors.Paused();
        _;
    }
    
    /// @dev Throws if the contract is not paused
    modifier whenPaused() {
        if (!S.protocol().paused) revert Errors.NotPaused();
        _;
    }

    /// @notice Ensures function can only be called when the specific vault is not paused
    modifier whenVaultNotPaused(uint32 vaultId) {
        if (S.protocol().vaults[vaultId].paused) revert Errors.Paused();
        _;
    }
    
    /// @dev Throws if the specified vault is not paused
    modifier whenVaultPaused(uint32 vaultId) {
        if (!S.protocol().vaults[vaultId].paused) revert Errors.NotPaused();
        _;
    }

    /// @notice Internal function to pause a specific vault
    /// @param vaultId ID of the vault to pause
    function _pauseVault(uint32 vaultId) internal {
        if (vaultId >= S.protocol().vaultCount) revert Errors.NotFound(ErrorType.VAULT);
        VaultStorage storage vs = S.protocol().vaults[vaultId];
        vs.paused = true;
        emit Events.VaultPaused(vaultId);
    }

    /// @notice Internal function to unpause a specific vault
    /// @param vaultId ID of the vault to unpause
    function _unpauseVault(uint32 vaultId) internal {
        if (vaultId >= S.protocol().vaultCount) revert Errors.NotFound(ErrorType.VAULT);
        VaultStorage storage vs = S.protocol().vaults[vaultId];
        vs.paused = false;
        emit Events.VaultUnpaused(vaultId);
    }
} 