// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title DEX Utils Library - DEX utility functions
 * @copyright 2025
 * @notice Contains utility functions for DEX operations and calculations
 * @dev Helper utilities for DEX-related operations
 * @author BTR Team
 */

library LibDEXUtils {
    function matchTokens(address _t00, address _t01, address _t10, address _t11)
        internal
        pure
        returns (bool matched, bool inverted)
    {
        if (_t00 == _t10 && _t01 == _t11) {
            return (true, false);
        } else if (_t00 == _t11 && _t01 == _t10) {
            return (true, true);
        } else {
            return (false, false);
        }
    }

    function checkMatchTokens(address _t00, address _t01, address _t10, address _t11)
        internal
        pure
        returns (bool inverted)
    {
        bool matched;
        (matched, inverted) = matchTokens(_t00, _t01, _t10, _t11);
        if (!matched) {
            revert Errors.UnexpectedInput();
        }
    }
}
