// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ICreateX} from "@interfaces/ICreateX.sol";
import {IDiamond, IDiamondCut, FacetCut, FacetCutAction} from "@interfaces/IDiamond.sol";
import {DiamondCutFacet} from "@facets/DiamondCutFacet.sol";

/**
 * @title DiamondCutFacetDeployer
 * @notice Self-destructing deployer for DiamondCutFacet
 * @dev Deploys DiamondCutFacet via CreateX, cuts it into diamond, then self-destructs
 */
contract DiamondCutFacetDeployer {
    ICreateX constant CREATEX = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);
    IDiamondCut constant DIAMOND = IDiamondCut(0xB71277d580D45F4Aa4E03cD261CA34527785B712);
    bytes32 constant SALT = 0x0a37aec263cba0aabc09bac56a0f2074a22e69a300bd8547f48cdb0302ad4c3e;
    address constant EXPECTED_ADDR = 0xb712dCA09c4327daC7789EA34574783dC554b712;

    constructor() {
        // Deploy the facet
        address deployed = CREATEX.deployCreate3(SALT, type(DiamondCutFacet).creationCode);
        require(deployed == EXPECTED_ADDR, "DiamondCutFacet deployment address mismatch");
        require(deployed != address(0), "DiamondCutFacet deployment failed");

        // Cut the facet into the diamond
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: deployed,
            action: FacetCutAction.Add,
            functionSelectors: _createSelectorArray(1, bytes4(keccak256("diamondCut((address,uint8,bytes4[])[],address,bytes)")))
        });

        DIAMOND.diamondCut(cuts, address(0), "");

        selfdestruct(payable(msg.sender));
    }

    // Helper function to create selector arrays
    function _createSelectorArray(uint256 count, bytes4 sel1) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2, bytes4 sel3) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2; selectors[2] = sel3;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2, bytes4 sel3, bytes4 sel4) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2; selectors[2] = sel3; selectors[3] = sel4;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2, bytes4 sel3, bytes4 sel4, bytes4 sel5) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2; selectors[2] = sel3; selectors[3] = sel4; selectors[4] = sel5;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2, bytes4 sel3, bytes4 sel4, bytes4 sel5, bytes4 sel6) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2; selectors[2] = sel3; selectors[3] = sel4; selectors[4] = sel5; selectors[5] = sel6;
        return selectors;
    }

    function _createSelectorArray(uint256 count, bytes4 sel1, bytes4 sel2, bytes4 sel3, bytes4 sel4, bytes4 sel5, bytes4 sel6, bytes4 sel7, bytes4 sel8, bytes4 sel9, bytes4 sel10, bytes4 sel11, bytes4 sel12, bytes4 sel13, bytes4 sel14, bytes4 sel15) private pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](count);
        selectors[0] = sel1; selectors[1] = sel2; selectors[2] = sel3; selectors[3] = sel4; selectors[4] = sel5;
        selectors[5] = sel6; selectors[6] = sel7; selectors[7] = sel8; selectors[8] = sel9; selectors[9] = sel10;
        selectors[10] = sel11; selectors[11] = sel12; selectors[12] = sel13; selectors[13] = sel14; selectors[14] = sel15;
        return selectors;
    }
}
