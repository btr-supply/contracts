// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {ICreateX} from "@interfaces/ICreateX.sol";
import {IDiamondCut, IDiamondLoupe, IDiamondCutCallback} from "@interfaces/IDiamond.sol";
import {IERC165} from "@interfaces/ercs/IERC165.sol";
import {IERC173} from "@interfaces/ercs/IERC173.sol";
import {InfoFacet} from "@facets/InfoFacet.sol";
import {ALMInfoFacet} from "@facets/ALMInfoFacet.sol";
import {ALMProtectedFacet} from "@facets/ALMProtectedFacet.sol";
import {ALMUserFacet} from "@facets/ALMUserFacet.sol";
import {AccessControlFacet} from "@facets/AccessControlFacet.sol";
import {BTRDiamond} from "@/BTRDiamond.sol";
import {DiamondCutFacet} from "@facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@facets/DiamondLoupeFacet.sol";
import {ManagementFacet} from "@facets/ManagementFacet.sol";
import {OracleFacet} from "@facets/OracleFacet.sol";
import {RescueFacet} from "@facets/RescueFacet.sol";
import {RiskModelFacet} from "@facets/RiskModelFacet.sol";
import {SwapFacet} from "@facets/SwapFacet.sol";
import {TreasuryFacet} from "@facets/TreasuryFacet.sol";

// Core imports

// Facet imports

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
        address swap;
        address alm_info;
        address alm_user;
        address alm_protected;
        address treasury;
        address info;
        address oracle;
        address risk_model;
    }

    /// @notice Salts for deterministic deployment
    struct Salts {
        bytes32 diamond;
        bytes32 access_control;
        bytes32 diamond_cut;
        bytes32 diamond_loupe;
        bytes32 management;
        bytes32 rescue;
        bytes32 swap;
        bytes32 alm_info;
        bytes32 alm_user;
        bytes32 alm_protected;
        bytes32 treasury;
        bytes32 info;
        bytes32 oracle;
        bytes32 risk_model;
    }

    function getAccessControlFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](32);
        selectors[0] = 0x36fc1787;
        selectors[1] = 0xf851a440;
        selectors[2] = 0x0269df4d;
        selectors[3] = 0xc5b95190;
        selectors[4] = 0x12d9a6ad;
        selectors[5] = 0x6a1f5b56;
        selectors[6] = 0xf0b7db4e;
        selectors[7] = 0x0e3944a4;
        selectors[8] = 0x2f2ff15d;
        selectors[9] = 0x91d14854;
        selectors[10] = 0xfea0c02e;
        selectors[11] = 0x24d7806c;
        selectors[12] = 0xfe575a87;
        selectors[13] = 0xdb9844d7;
        selectors[14] = 0x6ba42aaa;
        selectors[15] = 0xf3ae2415;
        selectors[16] = 0x516f0a1b;
        selectors[17] = 0x3af32abf;
        selectors[18] = 0x951dc22c;
        selectors[19] = 0x72311705;
        selectors[20] = 0x1f718bf4;
        selectors[21] = 0x8da5cb5b;
        selectors[22] = 0x8bb9c5bf;
        selectors[23] = 0xfabe3239;
        selectors[24] = 0xccc61d48;
        selectors[25] = 0x881043e8;
        selectors[26] = 0xd547741f;
        selectors[27] = 0x1e4e0091;
        selectors[28] = 0x1b3e17db;
        selectors[29] = 0x528391c3;
        selectors[30] = 0xf2fde38b;
        selectors[31] = 0x0e0523e4;
        return selectors;
    }

    function getDiamondCutFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = 0xf0b7db4e;
        selectors[1] = 0x1f931c1c;
        selectors[2] = 0xdb9844d7;
        return selectors;
    }

    function getDiamondLoupeFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = 0xcdffacc6;
        selectors[1] = 0x105db9f0;
        selectors[2] = 0xadfca15e;
        selectors[3] = 0x92b64171;
        selectors[4] = 0x7a0ed627;
        selectors[5] = 0xae008339;
        selectors[6] = 0xd321f735;
        selectors[7] = 0x01ffc9a7;
        return selectors;
    }

    function getManagementFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](23);
        selectors[0] = 0x44337ea1;
        selectors[1] = 0xc7054fbe;
        selectors[2] = 0xe43252d7;
        selectors[3] = 0xf0b7db4e;
        selectors[4] = 0xbc141374;
        selectors[5] = 0xdb9844d7;
        selectors[6] = 0x8456cb59;
        selectors[7] = 0x257f9abf;
        selectors[8] = 0x8829c167;
        selectors[9] = 0x0ad2b0a1;
        selectors[10] = 0x7b79211d;
        selectors[11] = 0x831b2a9a;
        selectors[12] = 0xd2ae6e69;
        selectors[13] = 0x54587d6c;
        selectors[14] = 0x0d95136e;
        selectors[15] = 0x6cb1a756;
        selectors[16] = 0x5560749b;
        selectors[17] = 0xb4bea817;
        selectors[18] = 0xa0da4e2c;
        selectors[19] = 0xc6f6d2e0;
        selectors[20] = 0x4174af93;
        selectors[21] = 0xf78203a7;
        selectors[22] = 0x3f4ba83a;
        return selectors;
    }

    function getRescueFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](23);
        selectors[0] = 0x819f930f;
        selectors[1] = 0x0fa9249a;
        selectors[2] = 0xf0b7db4e;
        selectors[3] = 0xcbc24ad8;
        selectors[4] = 0xe4646ff4;
        selectors[5] = 0xa0191509;
        selectors[6] = 0xdb9844d7;
        selectors[7] = 0x1d609f1b;
        selectors[8] = 0xf7b32222;
        selectors[9] = 0xcbbaf7a5;
        selectors[10] = 0xbc197c81;
        selectors[11] = 0xf23a6e61;
        selectors[12] = 0x150b7a02;
        selectors[13] = 0x4230da9f;
        selectors[14] = 0x96963d2c;
        selectors[15] = 0x5cf4381e;
        selectors[16] = 0xe56cc39f;
        selectors[17] = 0xcf40c9a0;
        selectors[18] = 0xe261eb86;
        selectors[19] = 0xd7fcf7c9;
        selectors[20] = 0xf4e99960;
        selectors[21] = 0x5e9aa7b5;
        selectors[22] = 0x52e6eb11;
        return selectors;
    }

    function getSwapFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = 0x98cd4036;
        selectors[1] = 0x0a6ce5b2;
        selectors[2] = 0xf0b7db4e;
        selectors[3] = 0x677391f7;
        selectors[4] = 0xdb9844d7;
        selectors[5] = 0x0e372109;
        selectors[6] = 0x32ef8314;
        selectors[7] = 0xe05ee954;
        return selectors;
    }

    function getALMInfoFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](51);
        selectors[0] = 0xcc67ecc2;
        selectors[1] = 0x77256f6d;
        selectors[2] = 0x27f161ab;
        selectors[3] = 0x94c89b2c;
        selectors[4] = 0x8aca42db;
        selectors[5] = 0x526aa01e;
        selectors[6] = 0xfc6a9f07;
        selectors[7] = 0xc3ea4f5f;
        selectors[8] = 0x9e32964d;
        selectors[9] = 0xc6d19d2b;
        selectors[10] = 0x1c7e41fe;
        selectors[11] = 0xa990c85b;
        selectors[12] = 0x9ca51111;
        selectors[13] = 0x7b37ff95;
        selectors[14] = 0xf247969f;
        selectors[15] = 0x8cebd942;
        selectors[16] = 0x24cb75c6;
        selectors[17] = 0x23c6c8de;
        selectors[18] = 0x68533da6;
        selectors[19] = 0xf5e83bc1;
        selectors[20] = 0x0f84d05b;
        selectors[21] = 0x03f354f2;
        selectors[22] = 0xe56a3cb9;
        selectors[23] = 0x43b70b71;
        selectors[24] = 0xafc99c4d;
        selectors[25] = 0x1eec5489;
        selectors[26] = 0xfa44c0c0;
        selectors[27] = 0x22b211bb;
        selectors[28] = 0xa3f23388;
        selectors[29] = 0x612b94be;
        selectors[30] = 0xe4253c63;
        selectors[31] = 0x02d3b886;
        selectors[32] = 0x781a9f57;
        selectors[33] = 0x1c71046e;
        selectors[34] = 0x1ceb6e10;
        selectors[35] = 0x62c4c267;
        selectors[36] = 0x1d8bc386;
        selectors[37] = 0x217b41d9;
        selectors[38] = 0x32b5226a;
        selectors[39] = 0x4219b33d;
        selectors[40] = 0x54f1b955;
        selectors[41] = 0x140724d4;
        selectors[42] = 0x72818ea9;
        selectors[43] = 0xe37a60e5;
        selectors[44] = 0x20328129;
        selectors[45] = 0x3d14335e;
        selectors[46] = 0x7288d381;
        selectors[47] = 0xa7c6a100;
        selectors[48] = 0x577c9512;
        selectors[49] = 0x1517a226;
        selectors[50] = 0xc7364af7;
        return selectors;
    }

    function getALMUserFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](25);
        selectors[0] = 0xc5896e8f;
        selectors[1] = 0x3f36df9f;
        selectors[2] = 0x739234b6;
        selectors[3] = 0x1102feda;
        selectors[4] = 0x214cd98c;
        selectors[5] = 0x11d1fbb1;
        selectors[6] = 0x0b8507af;
        selectors[7] = 0x5b166e78;
        selectors[8] = 0x196d3c44;
        selectors[9] = 0x79b447d0;
        selectors[10] = 0x83b1efbe;
        selectors[11] = 0x157d7def;
        selectors[12] = 0x86843c1b;
        selectors[13] = 0x9b8f6bd4;
        selectors[14] = 0x8d44c3ab;
        selectors[15] = 0x54fb7ee3;
        selectors[16] = 0x5a02fc03;
        selectors[17] = 0x0b9722ac;
        selectors[18] = 0x4e7b5211;
        selectors[19] = 0x30c2ff0a;
        selectors[20] = 0x64effbbb;
        selectors[21] = 0x13431347;
        selectors[22] = 0xde975b6d;
        selectors[23] = 0xfe71cb0b;
        selectors[24] = 0x4e5c7101;
        return selectors;
    }

    function getALMProtectedFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](17);
        selectors[0] = 0xd6007173;
        selectors[1] = 0xaef6a560;
        selectors[2] = 0xf0b7db4e;
        selectors[3] = 0xdb9844d7;
        selectors[4] = 0xcef9e2be;
        selectors[5] = 0x92764667;
        selectors[6] = 0x2800399a;
        selectors[7] = 0xcb89494e;
        selectors[8] = 0xf13a6439;
        selectors[9] = 0xa58aa67d;
        selectors[10] = 0x5154ac11;
        selectors[11] = 0x89016187;
        selectors[12] = 0x0e7d761d;
        selectors[13] = 0xd964f524;
        selectors[14] = 0x7ba1edb0;
        selectors[15] = 0xd4f58ffd;
        selectors[16] = 0x92ec2128;
        return selectors;
    }

    function getTreasuryFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = 0x2ec5e3c2;
        selectors[1] = 0x35b56e6e;
        selectors[2] = 0x913e77ad;
        selectors[3] = 0x118b48e5;
        selectors[4] = 0xf0b7db4e;
        selectors[5] = 0x63c5d245;
        selectors[6] = 0xdb9844d7;
        selectors[7] = 0x947016a5;
        selectors[8] = 0xfb5b82d0;
        selectors[9] = 0x4186f74b;
        selectors[10] = 0xecfa9b2d;
        return selectors;
    }

    function getInfoFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](32);
        selectors[0] = 0x61242bdd;
        selectors[1] = 0xac158ad0;
        selectors[2] = 0x50be1997;
        selectors[3] = 0x4232e3ea;
        selectors[4] = 0x5964973b;
        selectors[5] = 0x83ee5326;
        selectors[6] = 0x08456d6a;
        selectors[7] = 0x68967646;
        selectors[8] = 0x91907bd3;
        selectors[9] = 0x5c5218dd;
        selectors[10] = 0x026e2ab8;
        selectors[11] = 0x332c2e18;
        selectors[12] = 0xf00791d0;
        selectors[13] = 0x36ce5d54;
        selectors[14] = 0x4be461ef;
        selectors[15] = 0xcb3fbbfc;
        selectors[16] = 0xc01109a3;
        selectors[17] = 0xeae21c4c;
        selectors[18] = 0x5c46b8e7;
        selectors[19] = 0xc8aa644a;
        selectors[20] = 0x30f705e5;
        selectors[21] = 0xb2cf9afc;
        selectors[22] = 0x26bc9782;
        selectors[23] = 0xe32f0d3d;
        selectors[24] = 0x0072dab7;
        selectors[25] = 0x2fd84ef2;
        selectors[26] = 0x92b4a0ae;
        selectors[27] = 0x6e4f0e93;
        selectors[28] = 0x780f7906;
        selectors[29] = 0x2f900b32;
        selectors[30] = 0x54fd4d50;
        selectors[31] = 0x56914e84;
        return selectors;
    }

    function getOracleFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](31);
        selectors[0] = 0x248391ff;
        selectors[1] = 0x010b7e82;
        selectors[2] = 0x7b9c4e36;
        selectors[3] = 0xf0b7db4e;
        selectors[4] = 0xccb0101b;
        selectors[5] = 0xcc44b99a;
        selectors[6] = 0xef6f5b31;
        selectors[7] = 0x323d208b;
        selectors[8] = 0xcbf14336;
        selectors[9] = 0x7f6c2488;
        selectors[10] = 0x2562e0fa;
        selectors[11] = 0x8211e4f2;
        selectors[12] = 0xdb9844d7;
        selectors[13] = 0x93a7a730;
        selectors[14] = 0x67b802a2;
        selectors[15] = 0x8cf7dc1c;
        selectors[16] = 0x8086e07e;
        selectors[17] = 0x8a355a57;
        selectors[18] = 0xd88cb6d3;
        selectors[19] = 0x6e6e4e3f;
        selectors[20] = 0x77539ce0;
        selectors[21] = 0xaac0508a;
        selectors[22] = 0x1d3e0abb;
        selectors[23] = 0x45da9696;
        selectors[24] = 0x27e4b6b4;
        selectors[25] = 0x411eb892;
        selectors[26] = 0x50ff6f54;
        selectors[27] = 0x17aed874;
        selectors[28] = 0x52118afc;
        selectors[29] = 0xb2318190;
        selectors[30] = 0x63c42d49;
        return selectors;
    }

    function getRiskModelFacetSelectorst() public pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](20);
        selectors[0] = 0x2a137c3c;
        selectors[1] = 0xbb6f9171;
        selectors[2] = 0x66181564;
        selectors[3] = 0x9f815f38;
        selectors[4] = 0xf0b7db4e;
        selectors[5] = 0x16dfb4c7;
        selectors[6] = 0xdb9844d7;
        selectors[7] = 0x5c46b8e7;
        selectors[8] = 0x30f705e5;
        selectors[9] = 0x32c80db5;
        selectors[10] = 0x7df3e8ea;
        selectors[11] = 0x76b712ef;
        selectors[12] = 0x97ae996e;
        selectors[13] = 0x732e81d1;
        selectors[14] = 0x62d9ce5c;
        selectors[15] = 0x98d04e4f;
        selectors[16] = 0x9fbc236f;
        selectors[17] = 0xed0051e4;
        selectors[18] = 0x6c4bf428;
        selectors[19] = 0x56914e84;
        return selectors;
    }

    /*
     * @notice Get function selectors for a specific facet by name
     * @param facetName The name of the facet to get selectors for
     * @return Array of function selectors for the facet
     */
    function getSelectorsForFacet(string memory facetName) public pure returns (bytes4[] memory) {
        bytes32 nameHash = keccak256(bytes(facetName));

        if (nameHash == keccak256(bytes("AccessControlFacet"))) return getAccessControlFacetSelectorst();
        if (nameHash == keccak256(bytes("DiamondCutFacet"))) return getDiamondCutFacetSelectorst();
        if (nameHash == keccak256(bytes("DiamondLoupeFacet"))) return getDiamondLoupeFacetSelectorst();
        if (nameHash == keccak256(bytes("ManagementFacet"))) return getManagementFacetSelectorst();
        if (nameHash == keccak256(bytes("RescueFacet"))) return getRescueFacetSelectorst();
        if (nameHash == keccak256(bytes("SwapFacet"))) return getSwapFacetSelectorst();
        if (nameHash == keccak256(bytes("ALMInfoFacet"))) return getALMInfoFacetSelectorst();
        if (nameHash == keccak256(bytes("ALMUserFacet"))) return getALMUserFacetSelectorst();
        if (nameHash == keccak256(bytes("ALMProtectedFacet"))) return getALMProtectedFacetSelectorst();
        if (nameHash == keccak256(bytes("TreasuryFacet"))) return getTreasuryFacetSelectorst();
        if (nameHash == keccak256(bytes("InfoFacet"))) return getInfoFacetSelectorst();
        if (nameHash == keccak256(bytes("OracleFacet"))) return getOracleFacetSelectorst();
        if (nameHash == keccak256(bytes("RiskModelFacet"))) return getRiskModelFacetSelectorst();

        return new bytes4[](0);
    }

    /*
     * @notice Extract all facet cuts except DiamondCutFacet from deployed facets
     * @param deployment Deployment containing facets and facet names
     * @return Array of FacetCut structs without DiamondCutFacet
     */
    function getFunctionalCuts(Deployment memory deployment) public pure returns (IDiamondCut.FacetCut[] memory) {
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

    /*
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
        SwapFacet _SwapFacet = new SwapFacet();
        ALMInfoFacet _ALMInfoFacet = new ALMInfoFacet();
        ALMUserFacet _ALMUserFacet = new ALMUserFacet();
        ALMProtectedFacet _ALMProtectedFacet = new ALMProtectedFacet();
        TreasuryFacet _TreasuryFacet = new TreasuryFacet();
        InfoFacet _InfoFacet = new InfoFacet();
        OracleFacet _OracleFacet = new OracleFacet();
        RiskModelFacet _RiskModelFacet = new RiskModelFacet();

        // Now that the admin has all roles, we can initialize all the facets
        bytes4 initManagementFacetSelector = ManagementFacet.initializeManagement.selector;
        bytes4 initRescueFacetSelector = RescueFacet.initializeRescue.selector;
        bytes4 initSwapFacetSelector = SwapFacet.initializeSwap.selector;
        bytes4 initTreasuryFacetSelector = TreasuryFacet.initializeTreasury.selector;
        bytes4 initOracleFacetSelector = OracleFacet.initializeOracle.selector;
        bytes4 initRiskModelFacetSelector = RiskModelFacet.initializeRiskModel.selector;
        (bool success4,) = address(this).call(abi.encodePacked(initManagementFacetSelector));
        if (!success4) {}
        (bool success5,) = address(this).call(abi.encodePacked(initRescueFacetSelector));
        if (!success5) {}
        (bool success6,) = address(this).call(abi.encodePacked(initSwapFacetSelector));
        if (!success6) {}
        (bool success10,) = address(this).call(abi.encodePacked(initTreasuryFacetSelector));
        if (!success10) {}
        (bool success12,) = address(this).call(abi.encodePacked(initOracleFacetSelector));
        if (!success12) {}
        (bool success13,) = address(this).call(abi.encodePacked(initRiskModelFacetSelector));
        if (!success13) {}

        // Create FacetCut array for diamond constructor
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](12);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(_AccessControlFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getAccessControlFacetSelectorst()
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(_DiamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getDiamondLoupeFacetSelectorst()
        });
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(_ManagementFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getManagementFacetSelectorst()
        });
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(_RescueFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getRescueFacetSelectorst()
        });
        cuts[4] = IDiamondCut.FacetCut({
            facetAddress: address(_SwapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSwapFacetSelectorst()
        });
        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(_ALMInfoFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getALMInfoFacetSelectorst()
        });
        cuts[6] = IDiamondCut.FacetCut({
            facetAddress: address(_ALMUserFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getALMUserFacetSelectorst()
        });
        cuts[7] = IDiamondCut.FacetCut({
            facetAddress: address(_ALMProtectedFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getALMProtectedFacetSelectorst()
        });
        cuts[8] = IDiamondCut.FacetCut({
            facetAddress: address(_TreasuryFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getTreasuryFacetSelectorst()
        });
        cuts[9] = IDiamondCut.FacetCut({
            facetAddress: address(_InfoFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getInfoFacetSelectorst()
        });
        cuts[10] = IDiamondCut.FacetCut({
            facetAddress: address(_OracleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getOracleFacetSelectorst()
        });
        cuts[11] = IDiamondCut.FacetCut({
            facetAddress: address(_RiskModelFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getRiskModelFacetSelectorst()
        });

        // Initialize the diamond - only construct, don't make the diamond cut
        BTRDiamond diamond = new BTRDiamond(admin, treasury, address(_DiamondCutFacet));

        // Return deployment info without calling diamondCut
        address[] memory facets = new address[](13);
        facets[0] = address(_AccessControlFacet);
        facets[1] = address(_DiamondCutFacet);
        facets[2] = address(_DiamondLoupeFacet);
        facets[3] = address(_ManagementFacet);
        facets[4] = address(_RescueFacet);
        facets[5] = address(_SwapFacet);
        facets[6] = address(_ALMInfoFacet);
        facets[7] = address(_ALMUserFacet);
        facets[8] = address(_ALMProtectedFacet);
        facets[9] = address(_TreasuryFacet);
        facets[10] = address(_InfoFacet);
        facets[11] = address(_OracleFacet);
        facets[12] = address(_RiskModelFacet);
        string[] memory facetNames = new string[](13);
        facetNames[0] = "AccessControlFacet";
        facetNames[1] = "DiamondCutFacet";
        facetNames[2] = "DiamondLoupeFacet";
        facetNames[3] = "ManagementFacet";
        facetNames[4] = "RescueFacet";
        facetNames[5] = "SwapFacet";
        facetNames[6] = "ALMInfoFacet";
        facetNames[7] = "ALMUserFacet";
        facetNames[8] = "ALMProtectedFacet";
        facetNames[9] = "TreasuryFacet";
        facetNames[10] = "InfoFacet";
        facetNames[11] = "OracleFacet";
        facetNames[12] = "RiskModelFacet";

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
            swap: address(0),
            alm_info: address(0),
            alm_user: address(0),
            alm_protected: address(0),
            treasury: address(0),
            info: address(0),
            oracle: address(0),
            risk_model: address(0)
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
            swap: address(0),
            alm_info: address(0),
            alm_user: address(0),
            alm_protected: address(0),
            treasury: address(0),
            info: address(0),
            oracle: address(0),
            risk_model: address(0)
        });
    }
}
