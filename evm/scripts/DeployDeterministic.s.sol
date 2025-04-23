// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Deploy Deterministic - Salt-based deployment
 * @copyright 2025
 * @notice Manages CREATE2-based deterministic deployments
 * @dev Implements salt mining logic
 * @author BTR Team
 */

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {ICreateX} from "@interfaces/ICreateX.sol";
import {BTRDiamond} from "@/BTRDiamond.sol";
import {DiamondCutFacet} from "@facets/DiamondCutFacet.sol";
import {DiamondDeployer} from "@utils/generated/DiamondDeployer.gen.sol";

/**
 * @title DeployDeterministic
 * @notice Example script showing how to use DiamondDeployer for deterministic deployment
 */
contract DeployDeterministic is Script {
    // CreateX contract on mainnet
    ICreateX createX = ICreateX(vm.envAddress("CREATEX"));
    address deployer = vm.envAddress("DEPLOYER");
    uint256 deployerPk = vm.envUint("DEPLOYER_PK");

    function run() external {
        // Get deployer private key and address
        address admin = deployer;

        // Create DiamondDeployer instance
        DiamondDeployer diamondDeployer = new DiamondDeployer();

        // Define salts for each contract
        DiamondDeployer.Salts memory salts;
        salts.diamond = keccak256(bytes("btr.diamond.v1"));
        salts.diamond_cut = keccak256(bytes("btr.diamondCut.v1"));
        // Leave other salts as bytes32(0) to use default generation

        // Predict addresses
        DiamondDeployer.DeploymentAddresses memory predicted = diamondDeployer.predictDeterministicAddresses(
            salts,
            "btr", // Prefix for default salt generation
            deployer,
            createX
        );

        console.log("Deployer address:", deployer);
        console.log("Predicted DiamondCutFacet address:", predicted.diamond_cut);
        console.log("Predicted Diamond address:", predicted.diamond);

        // Demonstrate that a different deployer would get different addresses
        address anotherDeployer = address(0x123456);
        DiamondDeployer.DeploymentAddresses memory anotherPredicted =
            diamondDeployer.predictDeterministicAddresses(salts, "btr", anotherDeployer, createX);

        console.log("Another deployer:", anotherDeployer);
        console.log("Another deployer's DiamondCutFacet address:", anotherPredicted.diamond_cut);
        console.log("Another deployer's Diamond address:", anotherPredicted.diamond);

        // Start actual deployment
        vm.startBroadcast(deployerPk);

        // Deploy deterministically
        DiamondDeployer.DeploymentAddresses memory deployed =
            diamondDeployer.deployDeterministic(admin, salts, "btr", createX);

        vm.stopBroadcast();

        // Verify addresses match predictions
        console.log("Actual DiamondCutFacet address:", deployed.diamond_cut);
        console.log("Actual Diamond address:", deployed.diamond);

        require(deployed.diamond_cut == predicted.diamond_cut, "DiamondCutFacet address mismatch");
        require(deployed.diamond == predicted.diamond, "Diamond address mismatch");

        // Confirm addresses are different from other deployer's addresses
        require(
            deployed.diamond_cut != anotherPredicted.diamond_cut,
            "Addresses should be different for different deployers"
        );
        require(deployed.diamond != anotherPredicted.diamond, "Addresses should be different for different deployers");
    }
}
