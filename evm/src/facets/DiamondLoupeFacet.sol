// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {Diamond, ErrorType} from "@/BTRTypes.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibDiamond} from "@libraries/LibDiamond.sol";
import {IDiamondLoupe, Facet} from "@interfaces/IDiamond.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Diamond Loupe - Diamond introspection
 * @copyright 2025
 * @notice Implements EIP-2535 DiamondLoupe standard for querying facets and functions
 * @dev Standard facet for diamond introspection
 * @author BTR Team
 */

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    function facetsAddresses() external view override returns (Facet[] memory f) {
        Diamond storage diamond = S.diam();
        uint256 facetCount = diamond.facets.length;
        f = new Facet[](facetCount);

        for (uint256 i = 0; i < facetCount;) {
            address facetAddr = diamond.facets[i];
            f[i].facetAddress = facetAddr;
            f[i].functionSelectors = diamond.facetFunctionSelectors[facetAddr].functionSelectors;
            unchecked {
                ++i;
            }
        }

        return f;
    }

    function facetsPaginated(uint256 _start, uint256 _count) public view returns (Facet[] memory f) {
        Diamond storage diamond = S.diam();
        uint256 facetCount = diamond.facets.length;

        // Handle out-of-bounds start index
        if (_start >= facetCount) {
            return new Facet[](0);
        }

        // Calculate the actual range to return
        uint256 end = _start + _count;
        if (end > facetCount) {
            end = facetCount;
        }
        uint256 resultCount = end - _start;

        f = new Facet[](resultCount);

        for (uint256 i = 0; i < resultCount;) {
            address facetAddr = diamond.facets[_start + i];
            f[i].facetAddress = facetAddr;
            f[i].functionSelectors = diamond.facetFunctionSelectors[facetAddr].functionSelectors;
            unchecked {
                ++i;
            }
        }
    }

    function facets() external view override returns (Facet[] memory f) {
        return facetsPaginated(0, type(uint256).max);
    }

    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory selectors) {
        Diamond storage diamond = S.diam();
        selectors = diamond.facetFunctionSelectors[_facet].functionSelectors;
    }

    function facetFunctionSelectorsPaginated(address _facet, uint256 _start, uint256 _count)
        public
        view
        returns (bytes4[] memory selectors)
    {
        Diamond storage diamond = S.diam();
        bytes4[] memory allSelectors = diamond.facetFunctionSelectors[_facet].functionSelectors;
        uint256 selectorsCount = allSelectors.length;

        // Handle out-of-bounds start index
        if (_start >= selectorsCount) {
            return new bytes4[](0);
        }

        // Calculate the actual range to return
        uint256 end = _start + _count;
        if (end > selectorsCount) {
            end = selectorsCount;
        }
        uint256 resultCount = end - _start;

        selectors = new bytes4[](resultCount);

        for (uint256 i = 0; i < resultCount;) {
            selectors[i] = allSelectors[_start + i];
            unchecked {
                ++i;
            }
        }
    }

    function facetAddressesPaginated(uint256 _start, uint256 _count) public view returns (address[] memory addresses) {
        Diamond storage diamond = S.diam();
        uint256 addressesCount = diamond.facets.length;

        // Handle out-of-bounds start index
        if (_start >= addressesCount) {
            return new address[](0);
        }

        // Calculate the actual range to return
        uint256 end = _start + _count;
        if (end > addressesCount) {
            end = addressesCount;
        }
        uint256 resultCount = end - _start;

        addresses = new address[](resultCount);

        for (uint256 i = 0; i < resultCount;) {
            addresses[i] = diamond.facets[_start + i];
            unchecked {
                ++i;
            }
        }
    }

    function facetAddress(bytes4 _functionSelector) external view override returns (address) {
        return S.diam().selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        return S.diam().supportedInterfaces[_interfaceId];
    }
}
