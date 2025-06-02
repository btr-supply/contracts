// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {AccessControl, Diamond, FacetAddressAndPosition, ErrorType} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {IDiamondCut, FacetCut, FacetCutAction} from "@interfaces/IDiamond.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Diamond Library - Diamond pattern helpers
 * @copyright 2025
 * @notice Provides functions for interacting with diamond storage and facets
 * @dev Core library for EIP-2535 implementation
 * @author BTR Team
 */

library LibDiamond {
    function owner(AccessControl storage _ac) internal view returns (address) {
        return AC.admin(_ac);
    }

    function checkContractHasCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert Errors.NotFound(ErrorType.FACET);
        }
    }

    function diamondCut(Diamond storage _ds, FacetCut[] memory _diamondCut, address _init, bytes memory _calldata)
        internal
    {
        if (_ds.cutting) revert Errors.Locked();
        _ds.cutting = true;

        if (_diamondCut.length == 0) {
            revert Errors.NotFound(ErrorType.ACTION);
        }

        for (uint256 facetIndex; facetIndex < _diamondCut.length;) {
            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                addFunctions(_ds, _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(_ds, _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(_ds, _diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert Errors.NotFound(ErrorType.ACTION);
            }
            unchecked {
                ++facetIndex;
            }
        }
        emit IDiamondCut.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
        _ds.cutting = false;
    }

    function addFunctions(Diamond storage _ds, address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert Errors.NotFound(ErrorType.SELECTOR);
        }
        if (_facetAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        uint96 selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert Errors.AlreadyExists(ErrorType.FUNCTION);
            }
            addFunction(_ds, selector, selectorPosition, _facetAddress);
            emit Events.FunctionAdded(_facetAddress, selector);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function replaceFunctions(Diamond storage _ds, address _facetAddress, bytes4[] memory _functionSelectors)
        internal
    {
        if (_functionSelectors.length == 0) {
            revert Errors.NotFound(ErrorType.SELECTOR);
        }
        if (_facetAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        uint96 selectorPosition = uint96(_ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(_ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert Errors.AlreadyExists(ErrorType.FACET);
            }
            removeFunction(_ds, oldFacetAddress, selector);
            addFunction(_ds, selector, selectorPosition, _facetAddress);
            emit Events.FunctionReplaced(oldFacetAddress, _facetAddress, selector);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function removeFunctions(Diamond storage _ds, address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) revert Errors.NotFound(ErrorType.SELECTOR);
        if (_facetAddress != address(0)) revert Errors.ZeroAddress();

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _ds.selectorToFacetAndPosition[selector].facetAddress;

            removeFunction(_ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function addFacet(Diamond storage _ds, address _facetAddress) internal {
        checkContractHasCode(_facetAddress);
        _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = _ds.facets.length;
        _ds.facets.push(_facetAddress);
        emit Events.FacetAdded(_facetAddress);
    }

    function addFunction(Diamond storage _ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress)
        internal
    {
        _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        _ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(Diamond storage _ds, address _facetAddress, bytes4 _selector) internal {
        if (_facetAddress == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (_facetAddress == address(this)) {
            revert Errors.Unauthorized(ErrorType.ACTION); // immutable facet: diamond proxy itself
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            _ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        _ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete _ds.selectorToFacetAndPosition[_selector];
        emit Events.FunctionRemoved(_facetAddress, _selector);

        if (lastSelectorPosition == 0) {
            uint256 lastFacetAddressPosition = _ds.facets.length - 1;
            uint256 facetAddressPosition = _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _ds.facets[lastFacetAddressPosition];
                _ds.facets[facetAddressPosition] = lastFacetAddress;
                _ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _ds.facets.pop();
            delete _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            emit Events.FacetRemoved(_facetAddress);
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length != 0) {
                revert Errors.UnexpectedInput();
            }
        } else {
            if (_calldata.length == 0) {
                revert Errors.UnexpectedInput();
            }
            if (_init != address(this)) {
                checkContractHasCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                emit Events.InitializationFailed(_init, error);
                if (error.length > 0) {
                    assembly {
                        let ptr := add(error, 0x20)
                        revert(ptr, mload(error))
                    }
                } else {
                    revert Errors.InitializationFailed();
                }
            }
        }
    }

    function findFacetPosition(Diamond storage _ds, address _facetAddress)
        internal
        view
        returns (bool exists, uint256 position)
    {
        position = _ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        if (position < _ds.facets.length && _ds.facets[position] == _facetAddress) {
            return (true, position);
        }
        return (false, 0);
    }
}
