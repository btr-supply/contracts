// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    Diamond,
    AccessControl,
    ALMVault,
    CoreStorage,
    Rescue,
    Range,
    Treasury,
    Registry,
    Restrictions,
    Oracles,
    RiskModel,
    AddressType,
    AccountStatus
} from "@/BTRTypes.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Storage Library - Diamond storage layout definition
 * @copyright 2025
 * @notice Defines the storage layout for the BTR diamond proxy
 * @dev Central location for all diamond storage variables (AppStorage pattern)
 * @author BTR Team
 */

library BTRStorage {
    // --- STORAGE ---

    bytes32 constant DIAMOND_NS = keccak256("btr.diamond");
    bytes32 constant CORE_NS = keccak256("btr.core");
    bytes32 constant RESCUE_NS = keccak256("btr.rescue");

    // --- STORAGE ACCESSORS ---

    function diam() internal pure returns (Diamond storage _ds) {
        bytes32 position = DIAMOND_NS;
        assembly {
            _ds.slot := position
        }
    }

    function core() internal pure returns (CoreStorage storage _cs) {
        bytes32 position = CORE_NS;
        assembly {
            _cs.slot := position
        }
    }

    function tres() internal view returns (Treasury storage _tres) {
        return core().treasury;
    }

    function acc() internal view returns (AccessControl storage _ac) {
        return core().accessControl;
    }

    function rst() internal view returns (Restrictions storage _rs) {
        return core().restrictions;
    }

    function ora() internal view returns (Oracles storage _ora) {
        return core().oracles;
    }

    function reg() internal view returns (Registry storage _reg) {
        return core().registry;
    }

    function risk() internal view returns (RiskModel storage _rm) {
        return core().riskModel;
    }

    function res() internal pure returns (Rescue storage _res) {
        bytes32 position = RESCUE_NS;
        assembly {
            _res.slot := position
        }
    }
}
