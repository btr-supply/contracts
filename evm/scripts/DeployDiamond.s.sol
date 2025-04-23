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
 * @title Deploy Diamond - Mainnet deployment
 * @copyright 2025
 * @notice Handles production diamond deployment
 * @dev Uses safe upgrade patterns
 * @author BTR Team
 */

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {ICreateX} from "@interfaces/ICreateX.sol";
import {DiamondDeployer} from "@utils/generated/DiamondDeployer.gen.sol";

/**
 * @title DeployDiamond
 * @notice Forge script to deploy BTR Diamond architecture
 */
contract DeployDiamond is Script {
    function run() external {
        // Get deployer private key and address
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPk);
        address admin = deployer;
        address treasury = vm.envOr("TREASURY", address(0x1234));

        console.log("Deploying BTR Diamond with admin:", admin);
        console.log("Treasury address:", treasury);

        vm.startBroadcast(deployerPk);

        // Deploy diamond and all facets using the utility
        DiamondDeployer diamondDeployer = new DiamondDeployer();
        DiamondDeployer.Deployment memory deployment = diamondDeployer.deployDiamond(admin, treasury);

        vm.stopBroadcast();

        // Print deployment summary
        console.log("=========== Deployment Summary ===========");
        console.log("Diamond address:          ", address(deployment.diamond));

        // Access facets by index, using the expected order from the deployment script
        // The facet types are described in the facetNames array
        for (uint256 i = 0; i < deployment.facets.length && i < deployment.facetNames.length; i++) {
            console.log(string(abi.encodePacked(deployment.facetNames[i], " address:")), deployment.facets[i]);
        }

        console.log("Admin address:            ", admin);
        console.log("=========================================");
    }
}
