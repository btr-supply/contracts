// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {BTRErrors as Errors, BTREvents as Events} from "../libraries/BTREvents.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Adds/replaces/removes functions and optionally executes a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        // Check that the caller has the admin role
        LibAccessControl.checkRole(LibAccessControl.ADMIN_ROLE);
        
        // Execute the diamond cut
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
} 