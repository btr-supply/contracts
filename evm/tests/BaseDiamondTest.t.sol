// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {LibAccessControl} from "@libraries/LibAccessControl.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IDiamondCut} from "@interfaces/IDiamond.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {AccessControlFacet} from "@facets/AccessControlFacet.sol";
import {DiamondDeployer} from "@utils/generated/DiamondDeployer.gen.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Base Diamond Test - Base contract for diamond-related tests
 * @copyright 2025
 * @notice Provides common setup logic for deploying the diamond and initializing facets for testing
 * @dev Inherited by most unit and integration tests
 * @author BTR Team
 */

abstract contract BaseDiamondTest is Test, IERC721Receiver, IERC1155Receiver {
    // console is already globally available from forge-std

    address payable public diamond;
    address public admin; // single one
    address public manager; // one of several
    address public treasury; // single one
    address public keeper; // one of several
    address[3] users = [makeAddr("bob"), makeAddr("alice"), makeAddr("charlie")]; // 3 of many
    address public user = users[0];
    DiamondDeployer public deployer;

    function setUp() public virtual {
        // Setup addresses using environment variables or defaults
        uint256 adminPk = vm.envUint("DEPLOYER_PK");
        admin = vm.envOr("DEPLOYER", vm.addr(adminPk));
        manager = vm.envOr("MANAGER", admin);
        treasury = vm.envOr("TREASURY", admin);
        keeper = vm.envOr("KEEPER", admin);

        // Deploy diamond with all facets
        vm.startPrank(admin);

        // Deploy diamond and get facets
        deployer = new DiamondDeployer();
        DiamondDeployer.Deployment memory deployment = deployer.deployDiamond(admin, treasury);
        diamond = payable(deployment.diamond);

        // Get cuts array without DiamondCutFacet (already added in constructor)
        IDiamondCut.FacetCut[] memory cuts = deployer.getFunctionalCuts(deployment);
        IDiamondCut(diamond).diamondCut(cuts, address(0), "");
        vm.stopPrank();
    }

    // Standard ERC receiver implementations
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
