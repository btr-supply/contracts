// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibDiamond as D} from "@libraries/LibDiamond.sol";
import {IDiamondCut, FacetCut} from "@interfaces/IDiamond.sol";
import {NonReentrantFacet} from "@facets/abstract/NonReentrantFacet.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Diamond Cut - Upgrade functionality
 * @copyright 2025
 * @notice Handles diamond proxy upgrades and facet management
 * @dev Implements EIP-2535 diamond standard core upgrade logic
- Security Critical: Controls contract logic upgrades. Requires `onlyOwner` (implicitly admin via LibDiamond/initial setup)

 * @author BTR Team
 */

contract DiamondCutFacet is IDiamondCut, PermissionedFacet, NonReentrantFacet {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata)
        external
        override
        onlyAdmin
        nonReentrant
    {
        D.diamondCut(S.diam(), _diamondCut, _init, _calldata);
    }
}
