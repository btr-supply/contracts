// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ErrorType, AccountStatus as AS, Restrictions} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Restricted Functions - Access-controlled operations
 * @copyright 2025
 * @notice Contains permissioned protocol administration functions
 * @dev Integrates with AccessControlFacet for permissions
 * @author BTR Team
 */

abstract contract RestrictedFacet {
    using AC for uint32;
    using AC for address;

    modifier onlyNotBlacklisted(address _account) {
        AC.checkNotBlacklisted(S.rst(), _account);
        _;
    }

    modifier onlyWhitelisted(address _account) {
        AC.checkWhitelisted(S.rst(), _account);
        _;
    }

    modifier onlyUnlisted(address _account) {
        AC.checkUnlisted(S.rst(), _account);
        _;
    }

    modifier onlyUnrestrictedMinter(uint32 _vid, address _account) {
        AC.checkAlmMinterUnrestricted(S.rst(), _vid, _account);
        _;
    }
}
