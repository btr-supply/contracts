// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {Restrictions, ErrorType} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Non-Reentrant Facet - Prevents reentrancy attacks
 * @copyright 2025
 * @notice Implements a reentrancy guard modifier for facet functions
 * @dev Uses diamond storage for the reentrancy lock
 * @author BTR Team
 */

abstract contract NonReentrantFacet {
    modifier nonReentrant() {
        Restrictions storage rs = S.rst();
        if (rs.entered) revert Errors.Unauthorized(ErrorType.REENTRANCY);
        rs.entered = true;
        _;
        rs.entered = false;
    }
}
