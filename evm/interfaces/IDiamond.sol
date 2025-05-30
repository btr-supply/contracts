// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

struct FacetCut {
    address facetAddress;
    FacetCutAction action;
    bytes4[] functionSelectors;
}

interface IDiamondLoupe {
    function facetsAddresses() external view returns (Facet[] memory facets_);

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    function facets() external view returns (Facet[] memory facets_);

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

interface IDiamondCut {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

interface IDiamondCutCallback {
    function diamondCutCallback(address _diamond, FacetCut[] memory _cuts, address _init, bytes memory _calldata)
        external;
}

interface IDiamond {
    fallback() external payable;

    receive() external payable;
}
