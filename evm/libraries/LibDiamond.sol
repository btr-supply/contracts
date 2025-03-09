// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {BTRStorage as S} from "./BTRStorage.sol";
import {DiamondStorage} from "../BTRTypes.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {BTRErrors as Errors, BTREvents as Events} from "./BTREvents.sol";

library LibDiamond {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in functionSelectors array
    }

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Get the contract admin (first ADMIN_ROLE holder)
    /// @return Address of the first admin
    function contractOwner() internal view returns (address) {
        // Get admin role members
        address[] memory admins = LibAccessControl.getRoleMembers(LibAccessControl.ADMIN_ROLE);
        if (admins.length > 0) {
            return admins[0];
        }
        return address(0); // No admin found
    }

    /// @notice Set a new admin (replaces setContractOwner)
    /// @dev Creates a role acceptance for the new admin
    /// @param _newOwner New admin address
    function setContractOwner(address _newOwner) internal {
        // We'll emit the ownership transfer event to maintain compatibility
        address previousOwner = contractOwner();
        
        // Set up pending acceptance for admin role
        LibAccessControl.createRoleAcceptance(
            LibAccessControl.ADMIN_ROLE, 
            _newOwner, 
            previousOwner
        );
        
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice Enforce that the caller has admin privileges
    /// @dev Checks if caller has ADMIN_ROLE
    function enforceIsContractOwner() internal view {
        // Only check for ADMIN_ROLE now
        LibAccessControl.checkRole(LibAccessControl.ADMIN_ROLE, msg.sender);
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress, 
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress, 
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress, 
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert Errors.IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert Errors.NoSelectorsInFacet();
        }
        DiamondStorage storage ds = S.diamond();
        if (_facetAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        
        // Check if facet address already exists in facetAddresses
        uint256 facetPosition = 0;
        bool facetExists = false;
        for (; facetPosition < ds.facetAddresses.length; facetPosition++) {
            if (ds.facetAddresses[facetPosition] == _facetAddress) {
                facetExists = true;
                break;
            }
        }
        
        // Add new facet address if it doesn't exist
        if (!facetExists) {
            ds.facetAddresses.push(_facetAddress);
            ds.facetAddressPosition[_facetAddress] = ds.facetAddresses.length - 1;
        }
        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            bytes32 oldFacetAndPosition = ds.facetAddressAndSelectorPosition[selector];
            address oldFacetAddress = address(bytes20(oldFacetAndPosition));
            if (oldFacetAddress != address(0)) {
                revert Errors.FunctionAlreadyExists(selector);
            }
            
            // Add selector
            // Combine address and position: first 20 bytes = address, next bytes = selector position
            bytes32 selectorSlot = bytes32(uint256(uint160(_facetAddress))) | bytes32(selectorIndex << 160);
            ds.facetAddressAndSelectorPosition[selector] = selectorSlot;
            
            // Add to selector slots if needed
            if (selectorIndex >= ds.selectorSlots.length) {
                ds.selectorSlots.push(bytes32(selector));
            } else {
                ds.selectorSlots[selectorIndex] = bytes32(selector);
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert Errors.NoSelectorsInFacet();
        }
        DiamondStorage storage ds = S.diamond();
        if (_facetAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        
        // Check if facet address already exists in facetAddresses
        uint256 facetPosition = 0;
        bool facetExists = false;
        for (; facetPosition < ds.facetAddresses.length; facetPosition++) {
            if (ds.facetAddresses[facetPosition] == _facetAddress) {
                facetExists = true;
                break;
            }
        }
        
        // Add new facet address if it doesn't exist
        if (!facetExists) {
            ds.facetAddresses.push(_facetAddress);
            ds.facetAddressPosition[_facetAddress] = ds.facetAddresses.length - 1;
        }
        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            bytes32 oldFacetAndPosition = ds.facetAddressAndSelectorPosition[selector];
            address oldFacetAddress = address(bytes20(oldFacetAndPosition));
            if (oldFacetAddress == address(0)) {
                revert Errors.FunctionDoesNotExist(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert Errors.FunctionAlreadyOnFacet(selector);
            }
            
            // Remove old selector
            delete ds.facetAddressAndSelectorPosition[selector];
            
            // Add new selector
            bytes32 selectorSlot = bytes32(uint256(uint160(_facetAddress))) | bytes32(selectorIndex << 160);
            ds.facetAddressAndSelectorPosition[selector] = selectorSlot;
            
            // Update selector slots
            if (selectorIndex >= ds.selectorSlots.length) {
                ds.selectorSlots.push(bytes32(selector));
            } else {
                ds.selectorSlots[selectorIndex] = bytes32(selector);
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert Errors.NoSelectorsInFacet();
        }
        DiamondStorage storage ds = S.diamond();
        
        // If facet address is address(0), remove functions regardless of their facet
        bool checkFacetAddress = _facetAddress != address(0);
        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            bytes32 oldFacetAndPosition = ds.facetAddressAndSelectorPosition[selector];
            address oldFacetAddress = address(bytes20(oldFacetAndPosition));
            
            if (oldFacetAddress == address(0)) {
                revert Errors.FunctionDoesNotExist(selector);
            }
            if (checkFacetAddress && oldFacetAddress != _facetAddress) {
                revert Errors.FunctionNotFoundOnFacet(selector, _facetAddress);
            }
            
            // Remove the selector
            delete ds.facetAddressAndSelectorPosition[selector];
            
            // If this was the last selector for the facet, remove the facet
            bool lastSelectorForFacet = true;
            for (uint256 i = 0; i < ds.selectorSlots.length; i++) {
                bytes4 otherSelector = bytes4(ds.selectorSlots[i]);
                bytes32 otherFacetAndPosition = ds.facetAddressAndSelectorPosition[otherSelector];
                address otherFacetAddress = address(bytes20(otherFacetAndPosition));
                
                if (otherFacetAddress == oldFacetAddress) {
                    lastSelectorForFacet = false;
                    break;
                }
            }
            
            // If this was the last selector for the facet, remove facet address
            if (lastSelectorForFacet) {
                uint256 lastFacetIndex = ds.facetAddresses.length - 1;
                uint256 facetIndex = ds.facetAddressPosition[oldFacetAddress];
                
                // If not the last facet address, swap with the last one
                if (facetIndex != lastFacetIndex) {
                    address lastFacetAddress = ds.facetAddresses[lastFacetIndex];
                    ds.facetAddresses[facetIndex] = lastFacetAddress;
                    ds.facetAddressPosition[lastFacetAddress] = facetIndex;
                }
                
                // Remove the last facet address
                ds.facetAddresses.pop();
                delete ds.facetAddressPosition[oldFacetAddress];
            }
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        if (_init.code.length == 0) {
            revert Errors.FacetHasNoCode(_init);
        }
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // Bubble up the error
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert Errors.InitFunctionReverted(_init);
            }
        }
    }
} 