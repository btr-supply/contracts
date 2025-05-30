// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibPausable as P} from "@libraries/LibPausable.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Pausable - Emergency pause functionality
 * @copyright 2025
 * @notice Provides emergency stop mechanism for protocol operations
 * @dev Inherits from OpenZeppelin Pausable with diamond storage pattern
 * @author BTR Team
 */

abstract contract PausableFacet {
    using U for uint32;
    // vault level pause

    function isAlmVaultPaused(uint32 _vid) external view returns (bool) {
        return P.isAlmVaultPaused(_vid.vault());
    }

    modifier whenVaultNotPaused(uint32 _vid) virtual {
        if (P.isAlmVaultPaused(_vid.vault()) || P.isPaused()) revert Errors.Paused(ErrorType.VAULT);
        _;
    }

    modifier whenVaultPaused(uint32 _vid) virtual {
        if (!P.isAlmVaultPaused(_vid.vault()) && !P.isPaused()) {
            revert Errors.NotPaused(ErrorType.VAULT);
        }
        _;
    }

    // protocol level pause
    function isPaused() external view returns (bool) {
        return P.isPaused();
    }

    modifier whenNotPaused() virtual {
        if (P.isPaused()) revert Errors.Paused(ErrorType.PROTOCOL);
        _;
    }

    modifier whenPaused() virtual {
        if (!P.isPaused()) revert Errors.NotPaused(ErrorType.PROTOCOL);
        _;
    }
}
