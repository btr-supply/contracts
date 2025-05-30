// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccessControl, Diamond, ErrorType} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibDiamond as D} from "@libraries/LibDiamond.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IDiamondCut, IDiamondLoupe, IDiamond, FacetCut, FacetCutAction} from "@interfaces/IDiamond.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Diamond Contract - Main diamond proxy contract implementation
 * @copyright 2025
 * @notice The main entry point for the BTR protocol, implementing the EIP-2535 diamond standard
 * @dev Inherits from LibDiamond and uses BTRStorage
 * @author BTR Team
 */

contract BTRDiamond is IDiamond {
    using D for address;

    constructor(address _owner, address _treasury, address _cutFacet) payable {
        if (_owner == address(0)) revert Errors.ZeroAddress(); // Prevent zero owner address
        if (_treasury == address(0)) revert Errors.ZeroAddress(); // Prevent zero treasury address
        if (_cutFacet == address(0)) {
            revert Errors.NotFound(ErrorType.FACET); // Prevent missing diamond cut facet
        }
        _cutFacet.checkContractHasCode(); // Ensure facet is a contract
        AC.initialize(S.acc(), _owner, _treasury); // Initialize access control
        T.setCollector(_treasury); // Set treasury collector

        FacetCut[] memory cut = new FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = FacetCut({facetAddress: _cutFacet, action: FacetCutAction.Add, functionSelectors: functionSelectors});
        D.diamondCut(S.diam(), cut, address(0), ""); // Initialize diamond cut
        Diamond storage diamond = S.diamond();
        diamond.supportedInterfaces[type(IERC165).interfaceId] = true;
        diamond.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        diamond.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        diamond.supportedInterfaces[type(IERC721Receiver).interfaceId] = true; // rescuable/drops
        diamond.supportedInterfaces[type(IERC1155Receiver).interfaceId] = true; // rescuable/drops
    }

    fallback() external payable {
        Diamond storage diamond = S.diamond();
        address facet = diamond.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) revert Errors.NotFound(ErrorType.FUNCTION); // Function not found in any facet
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}
