// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ALMVault, ErrorType, Restrictions} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Pausable Library - Shared pause functionality logic
 * @copyright 2025
 * @notice Provides internal functions for pause/unpause checks using diamond storage
 * @dev Helper library for PausableFacet and abstract Pausable
 * @author BTR Team
 */

library LibPausable {
    using U for uint32;
    // --- PAUSE ---
    // vault level pause

    function pauseAlmVault(ALMVault storage _vault) internal {
        _vault.paused = true;
        emit Events.Paused(_vault.id, msg.sender);
    }

    function unpauseAlmVault(ALMVault storage _vault) internal {
        if (!_vault.paused) revert Errors.NotPaused(ErrorType.VAULT);
        _vault.paused = false;
        emit Events.Unpaused(_vault.id, msg.sender);
    }

    function isAlmVaultPaused(ALMVault storage _vault) internal view returns (bool) {
        return _vault.paused;
    }

    // protocol level pause
    function pause() internal {
        pauseAlmVault(uint32(0).vault());
    }

    function unpause() internal {
        unpauseAlmVault(uint32(0).vault());
    }

    function isPaused() internal view returns (bool) {
        return isAlmVaultPaused(uint32(0).vault());
    }
}
