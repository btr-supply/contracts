// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Pausable - Emergency pause functionality
 * @copyright 2025
 * @notice Provides emergency stop mechanism for protocol operations
 * @dev Inherits from OpenZeppelin Pausable with diamond storage pattern
 * @author BTR Team
 */

import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {LibPausable as P} from "@libraries/LibPausable.sol";
import {ErrorType} from "@/BTRTypes.sol";

abstract contract PausableFacet {
    function isPaused() external view returns (bool) {
        return P.isPaused();
    }

    function isPaused(uint32 vaultId) external view returns (bool) {
        return P.isPaused(vaultId);
    }

    modifier whenNotPaused() virtual {
        if (P.isPaused()) revert Errors.Paused(ErrorType.PROTOCOL);
        _;
    }

    modifier whenPaused() virtual {
        if (!P.isPaused()) revert Errors.NotPaused(ErrorType.PROTOCOL);
        _;
    }

    modifier whenVaultNotPaused(uint32 vaultId) virtual {
        if (P.isPaused(vaultId) || P.isPaused()) revert Errors.Paused(ErrorType.VAULT);
        _;
    }

    modifier whenVaultPaused(uint32 vaultId) virtual {
        if (!P.isPaused(vaultId) && !P.isPaused()) revert Errors.NotPaused(ErrorType.VAULT);
        _;
    }
}
