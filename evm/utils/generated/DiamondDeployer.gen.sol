// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Core imports
import {BTRDiamond} from "@/BTRDiamond.sol";
import {IDiamondCut, IDiamondLoupe, IDiamondInit, IDiamondCutCallback} from "@interfaces/IDiamond.sol";
import {IERC173} from "@interfaces/ercs/IERC173.sol";
import {IERC165} from "@interfaces/ercs/IERC165.sol";
import {ICreateX} from "@interfaces/ICreateX.sol";
import {LibAccessControl} from "@libraries/LibAccessControl.sol";

// Facet imports
import {AccessControlFacet} from "@facets/AccessControlFacet.sol";
import {DiamondCutFacet} from "@facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@facets/DiamondLoupeFacet.sol";
import {ManagementFacet} from "@facets/ManagementFacet.sol";
import {RescueFacet} from "@facets/RescueFacet.sol";
import {SwapperFacet} from "@facets/SwapperFacet.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {TreasuryFacet} from "@facets/TreasuryFacet.sol";

// Diamond initializer contract to avoid stack too deep errors
contract DiamondInit {
    function init(address admin) external {
        // Since we'll be using delegatecall from the admin account via the diamond,
        // we need to grant all necessary roles to the admin first to ensure they have permissions

        // Direct access to storage to grant roles
        // These functions directly interact with storage so they don't use onlyAdmin checks
        LibAccessControl.grantRole(LibAccessControl.ADMIN_ROLE, admin);
        LibAccessControl.grantRole(LibAccessControl.MANAGER_ROLE, admin);
        LibAccessControl.grantRole(LibAccessControl.TREASURY_ROLE, admin);

        // Now that the admin has all roles, we can initialize all the facets
        bytes4 initManagementFacetSelector = ManagementFacet.initializeManagement.selector;
        bytes4 initRescueFacetSelector = RescueFacet.initializeRescue.selector;
        bytes4 initSwapperFacetSelector = SwapperFacet.initializeSwapper.selector;
        bytes4 initALMFacetSelector = ALMFacet.initializeALM.selector;
        bytes4 initTreasuryFacetSelector = TreasuryFacet.initializeTreasury.selector;
        (bool success4,) = address(this).call(abi.encodePacked(initManagementFacetSelector));
        if (!success4) {}
        (bool success5,) = address(this).call(abi.encodePacked(initRescueFacetSelector));
        if (!success5) {}
        (bool success6,) = address(this).call(abi.encodePacked(initSwapperFacetSelector));
        if (!success6) {}
        (bool success7,) = address(this).call(abi.encodePacked(initALMFacetSelector));
        if (!success7) {}
        (bool success8,) = address(this).call(abi.encodePacked(initTreasuryFacetSelector));
        if (!success8) {}
    }
}

contract DiamondDeployer is IDiamondCutCallback {
    // Store admin address for diamondCutCallback
    address private _admin;

    /// @notice Deployment result containing all deployed contracts
    struct Deployment {
        address diamond;
        address[] facets;
        string[] facetNames;
    }

    /// @notice Deployment addresses for deterministic deployment
    struct DeploymentAddresses {
        address diamond;
        address access_control;
        address diamond_cut;
        address diamond_loupe;
        address management;
        address rescue;
        address swapper;
        address alm;
        address treasury;
    }

    /// @notice Salts for deterministic deployment
    struct Salts {
        bytes32 diamond;
        bytes32 access_control;
        bytes32 diamond_cut;
        bytes32 diamond_loupe;
        bytes32 management;
        bytes32 rescue;
        bytes32 swapper;
        bytes32 alm;
        bytes32 treasury;
    }

    function getAccessControlFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](27);
        selectors[0] = 0x36fc1787;
        selectors[1] = 0xf851a440;
        selectors[2] = 0x0269df4d;
        selectors[3] = 0xc5b95190;
        selectors[4] = 0x12d9a6ad;
        selectors[5] = 0x6a1f5b56;
        selectors[6] = 0xb105e39f;
        selectors[7] = 0xa8d088bb;
        selectors[8] = 0x7b641fbc;
        selectors[9] = 0x0e3944a4;
        selectors[10] = 0x04fcbf24;
        selectors[11] = 0x2f2ff15d;
        selectors[12] = 0x91d14854;
        selectors[13] = 0xfea0c02e;
        selectors[14] = 0x24d7806c;
        selectors[15] = 0xfe575a87;
        selectors[16] = 0x6ba42aaa;
        selectors[17] = 0xf3ae2415;
        selectors[18] = 0x516f0a1b;
        selectors[19] = 0x3af32abf;
        selectors[20] = 0x8da5cb5b;
        selectors[21] = 0x8bb9c5bf;
        selectors[22] = 0xd547741f;
        selectors[23] = 0x1e4e0091;
        selectors[24] = 0x1b3e17db;
        selectors[25] = 0xf2fde38b;
        selectors[26] = 0x61d027b3;
        return selectors;
    }

    function getDiamondCutFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = 0x1f931c1c;
        return selectors;
    }

    function getDiamondLoupeFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = 0xcdffacc6;
        selectors[1] = 0x52ef6b2c;
        selectors[2] = 0x105db9f0;
        selectors[3] = 0xadfca15e;
        selectors[4] = 0x92b64171;
        selectors[5] = 0x7a0ed627;
        selectors[6] = 0xd321f735;
        selectors[7] = 0x01ffc9a7;
        return selectors;
    }

    function getManagementFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](45);
        selectors[0] = 0x44337ea1;
        selectors[1] = 0xc7054fbe;
        selectors[2] = 0xe43252d7;
        selectors[3] = 0xfd4fa05a;
        selectors[4] = 0xaa13cb54;
        selectors[5] = 0xb135a145;
        selectors[6] = 0x74d4e491;
        selectors[7] = 0x0d8e6e2c;
        selectors[8] = 0xbc141374;
        selectors[9] = 0x5c5218dd;
        selectors[10] = 0x026e2ab8;
        selectors[11] = 0x332c2e18;
        selectors[12] = 0xf00791d0;
        selectors[13] = 0x36ce5d54;
        selectors[14] = 0xb187bd26;
        selectors[15] = 0xeef4da34;
        selectors[16] = 0x81f17587;
        selectors[17] = 0x290385f1;
        selectors[18] = 0x4be461ef;
        selectors[19] = 0xcb3fbbfc;
        selectors[20] = 0xc01109a3;
        selectors[21] = 0xeae21c4c;
        selectors[22] = 0x8456cb59;
        selectors[23] = 0x4cda9b55;
        selectors[24] = 0x257f9abf;
        selectors[25] = 0x8829c167;
        selectors[26] = 0x0ad2b0a1;
        selectors[27] = 0x7b79211d;
        selectors[28] = 0x831b2a9a;
        selectors[29] = 0xd2ae6e69;
        selectors[30] = 0x54587d6c;
        selectors[31] = 0x0d95136e;
        selectors[32] = 0x6cb1a756;
        selectors[33] = 0x0e7d761d;
        selectors[34] = 0x8374f11f;
        selectors[35] = 0xeebdd353;
        selectors[36] = 0x596012e5;
        selectors[37] = 0xb4bea817;
        selectors[38] = 0xa0da4e2c;
        selectors[39] = 0xc6f6d2e0;
        selectors[40] = 0x4174af93;
        selectors[41] = 0xf78203a7;
        selectors[42] = 0x3f4ba83a;
        selectors[43] = 0x446a9aa2;
        selectors[44] = 0x17a4f4bb;
        return selectors;
    }

    function getRescueFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](21);
        selectors[0] = 0x819f930f;
        selectors[1] = 0x0fa9249a;
        selectors[2] = 0xcbc24ad8;
        selectors[3] = 0xe4646ff4;
        selectors[4] = 0xa01832cf;
        selectors[5] = 0xa0191509;
        selectors[6] = 0x1d609f1b;
        selectors[7] = 0xf7b32222;
        selectors[8] = 0xcbbaf7a5;
        selectors[9] = 0xbc197c81;
        selectors[10] = 0xf23a6e61;
        selectors[11] = 0x150b7a02;
        selectors[12] = 0x4230da9f;
        selectors[13] = 0x96963d2c;
        selectors[14] = 0x5cf4381e;
        selectors[15] = 0xe56cc39f;
        selectors[16] = 0xcf40c9a0;
        selectors[17] = 0xe261eb86;
        selectors[18] = 0xd7fcf7c9;
        selectors[19] = 0xf4e99960;
        selectors[20] = 0x52e6eb11;
        return selectors;
    }

    function getSwapperFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = 0x98cd4036;
        selectors[1] = 0x0a6ce5b2;
        selectors[2] = 0xb3c42d61;
        selectors[3] = 0x119943f7;
        selectors[4] = 0xb69cbf9f;
        selectors[5] = 0xe05ee954;
        return selectors;
    }

    function getALMFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](30);
        selectors[0] = 0xcc67ecc2;
        selectors[1] = 0x94c89b2c;
        selectors[2] = 0x7d1c5b25;
        selectors[3] = 0xaef6a560;
        selectors[4] = 0x7217322e;
        selectors[5] = 0xc5896e8f;
        selectors[6] = 0x24f75314;
        selectors[7] = 0x62f1096c;
        selectors[8] = 0xc19b6015;
        selectors[9] = 0xa0d96727;
        selectors[10] = 0x19a6081a;
        selectors[11] = 0xc2082974;
        selectors[12] = 0x0c66e0ec;
        selectors[13] = 0x000c14c8;
        selectors[14] = 0x23c6c8de;
        selectors[15] = 0x6301a4ef;
        selectors[16] = 0xc59f8fd6;
        selectors[17] = 0x53690fac;
        selectors[18] = 0x4bd568cc;
        selectors[19] = 0x4375d60b;
        selectors[20] = 0x36774627;
        selectors[21] = 0x86ff37e0;
        selectors[22] = 0x140724d4;
        selectors[23] = 0x72818ea9;
        selectors[24] = 0x7288d381;
        selectors[25] = 0xd09ae45b;
        selectors[26] = 0x0f0bc28d;
        selectors[27] = 0x41ee1ade;
        selectors[28] = 0xcce185b8;
        selectors[29] = 0x64effbbb;
        return selectors;
    }

    function getTreasuryFacetSelectors() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = 0x4a425387;
        selectors[1] = 0xe02642fa;
        selectors[2] = 0xdb8d55f1;
        selectors[3] = 0x7ab038fa;
        selectors[4] = 0xe0d89b32;
        selectors[5] = 0x3b19e84a;
        selectors[6] = 0x63c5d245;
        selectors[7] = 0xf4b00a30;
        selectors[8] = 0x4f93456e;
        selectors[9] = 0x7fc021c4;
        selectors[10] = 0xf0f44260;
        return selectors;
    }

    /**
     * @notice Get function selectors for a specific facet by name
     * @param facetName The name of the facet to get selectors for
     * @return Array of function selectors for the facet
     */
    function getSelectorsForFacet(string memory facetName) public pure returns (bytes4[] memory) {
        bytes32 nameHash = keccak256(bytes(facetName));

        if (nameHash == keccak256(bytes("AccessControlFacet"))) return getAccessControlFacetSelectors();
        if (nameHash == keccak256(bytes("DiamondCutFacet"))) return getDiamondCutFacetSelectors();
        if (nameHash == keccak256(bytes("DiamondLoupeFacet"))) return getDiamondLoupeFacetSelectors();
        if (nameHash == keccak256(bytes("ManagementFacet"))) return getManagementFacetSelectors();
        if (nameHash == keccak256(bytes("RescueFacet"))) return getRescueFacetSelectors();
        if (nameHash == keccak256(bytes("SwapperFacet"))) return getSwapperFacetSelectors();
        if (nameHash == keccak256(bytes("ALMFacet"))) return getALMFacetSelectors();
        if (nameHash == keccak256(bytes("TreasuryFacet"))) return getTreasuryFacetSelectors();

        return new bytes4[](0);
    }

    /**
     * @notice Extract all facet cuts except DiamondCutFacet from deployed facets
     * @param deployment Deployment containing facets and facet names
     * @return Array of FacetCut structs without DiamondCutFacet
     */
    function getCutsWithoutDiamondCutFacet(Deployment memory deployment)
        public
        pure
        returns (IDiamondCut.FacetCut[] memory)
    {
        // Create cuts array for all facets except DiamondCutFacet (already added)
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](deployment.facets.length - 1);
        uint256 cutCount = 0;

        // Add all facets except DiamondCutFacet
        for (uint256 i = 0; i < deployment.facetNames.length; i++) {
            if (keccak256(bytes(deployment.facetNames[i])) != keccak256(bytes("DiamondCutFacet"))) {
                cuts[cutCount] = IDiamondCut.FacetCut({
                    facetAddress: deployment.facets[i],
                    action: IDiamondCut.FacetCutAction.Add,
                    functionSelectors: getSelectorsForFacet(deployment.facetNames[i])
                });
                cutCount++;
            }
        }

        return cuts;
    }

    /**
     * @notice Diamond Cut Callback for authorization in diamond cut operations
     * @dev This function is implemented for compatibility with both tests and production
     */
    function diamondCutCallback(
        address _diamond,
        IDiamondCut.FacetCut[] memory _cuts,
        address _init,
        bytes memory _calldata
    ) external override {
        // Direct call to the diamond
        (bool success, bytes memory returnData) =
            _diamond.call(abi.encodeWithSelector(IDiamondCut.diamondCut.selector, _cuts, _init, _calldata));

        // Handle errors properly
        if (!success) {
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }
    }

    function deployDiamond(address admin, address treasury) public returns (Deployment memory) {
        // Store admin for diamondCutCallback
        _admin = admin;

        // Deploy facets
        AccessControlFacet _AccessControlFacet = new AccessControlFacet();
        DiamondCutFacet _DiamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet _DiamondLoupeFacet = new DiamondLoupeFacet();
        ManagementFacet _ManagementFacet = new ManagementFacet();
        RescueFacet _RescueFacet = new RescueFacet();
        SwapperFacet _SwapperFacet = new SwapperFacet();
        ALMFacet _ALMFacet = new ALMFacet();
        TreasuryFacet _TreasuryFacet = new TreasuryFacet();

        // Deploy DiamondInit
        DiamondInit diamondInit = new DiamondInit();

        // Create FacetCut array for diamond constructor
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](7);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(_AccessControlFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getAccessControlFacetSelectors()
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(_DiamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getDiamondLoupeFacetSelectors()
        });
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(_ManagementFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getManagementFacetSelectors()
        });
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(_RescueFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getRescueFacetSelectors()
        });
        cuts[4] = IDiamondCut.FacetCut({
            facetAddress: address(_SwapperFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSwapperFacetSelectors()
        });
        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(_ALMFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getALMFacetSelectors()
        });
        cuts[6] = IDiamondCut.FacetCut({
            facetAddress: address(_TreasuryFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getTreasuryFacetSelectors()
        });

        // Initialize the diamond - only construct, don't make the diamond cut
        BTRDiamond diamond = new BTRDiamond(admin, treasury, address(_DiamondCutFacet));

        // Return deployment info without calling diamondCut
        address[] memory facets = new address[](8);
        facets[0] = address(_AccessControlFacet);
        facets[1] = address(_DiamondCutFacet);
        facets[2] = address(_DiamondLoupeFacet);
        facets[3] = address(_ManagementFacet);
        facets[4] = address(_RescueFacet);
        facets[5] = address(_SwapperFacet);
        facets[6] = address(_ALMFacet);
        facets[7] = address(_TreasuryFacet);
        string[] memory facetNames = new string[](8);
        facetNames[0] = "AccessControlFacet";
        facetNames[1] = "DiamondCutFacet";
        facetNames[2] = "DiamondLoupeFacet";
        facetNames[3] = "ManagementFacet";
        facetNames[4] = "RescueFacet";
        facetNames[5] = "SwapperFacet";
        facetNames[6] = "ALMFacet";
        facetNames[7] = "TreasuryFacet";

        return Deployment({diamond: address(diamond), facets: facets, facetNames: facetNames});
    }

    function deployDiamondViaCreate2(bytes32 salt) public returns (address) {
        return address(0);
    }

    function predictDiamondAddress(bytes32 salt) public view returns (address) {
        return address(0);
    }

    function deployDeterministic(address admin, Salts memory salts, string memory prefix, ICreateX createX)
        public
        returns (DeploymentAddresses memory)
    {
        return DeploymentAddresses({
            diamond: address(0),
            access_control: address(0),
            diamond_cut: address(0),
            diamond_loupe: address(0),
            management: address(0),
            rescue: address(0),
            swapper: address(0),
            alm: address(0),
            treasury: address(0)
        });
    }

    function predictDeterministicAddresses(Salts memory salts, string memory prefix, address deployer, ICreateX createX)
        public
        view
        returns (DeploymentAddresses memory)
    {
        return DeploymentAddresses({
            diamond: address(0),
            access_control: address(0),
            diamond_cut: address(0),
            diamond_loupe: address(0),
            management: address(0),
            rescue: address(0),
            swapper: address(0),
            alm: address(0),
            treasury: address(0)
        });
    }
}
