// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@libraries/LibCast.sol";
import "@interfaces/ICreateX.sol";
import "forge-std/Test.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Create3Test - Production deployment verification
 * @copyright 2025
 * @notice Validates CreateX salt computations against known good pairs
 * @dev Tests salts from salts-b712_b712.txt with correct deployer.
 * @author BTR Team.
 */

contract Create3Test is Test {
    address constant CREATEX = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;
    address constant DEPLOYER = 0x0a37aEc263CbA0aaBC09Bac56A0F2074a22E69A3;

    function setUp() public pure {
        console.log("Using deployer:", DEPLOYER);
    }

    struct Pair {
      bytes32 s;
      address a;
    }

    function test_ProductionSalts() public {
        // Fork BNB Chain for consistent results
        vm.createSelectFork("https://bsc-dataseed.bnbchain.org");

        ICreateX createX = ICreateX(CREATEX);
        // Test all salt/address pairs from salts-b712_b712.txt
        Pair[19] memory pairs = [
          // Main contracts (B712...B712)
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300f9dc05ebadfeea0076dd1a, 0xB71277d580D45F4Aa4E03cD261CA34527785B712), // diamond
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300637409d4a5539601c914cc, 0xB7126f81759Cf7495721e70c0765A6fCcE72B712), // btr
          // Facets (b712...b712)
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a30030d6f06d1a2b1002c664a2, 0xb7127AE785907441BFBC6C7bDAcC339CD7e2b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300bd8547f48cdb0302ad4c3e, 0xb712dCA09c4327daC7789EA34574783dC554b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300f97afd86eb2822037ef997, 0xb7122066D05B248FB3F09025EFe1db9d1761b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a3007364b2b87a4d7f01969bc2, 0xb7128212286a6e7f4fEF52E9c5CE6963C75ab712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a30034678660a51ffe032a91de, 0xb71269762A37C3bAaE98Bc1C9d95aec3885Fb712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a3009083cfa69f58ef012aaf17, 0xb7120441f633D69E9DA41ba35Ea34C5FDDC0b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300cd34ffd7f2032b0224f7f9, 0xb712Ad3BF61287d5215967B46AB004d4D8F8b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a3006b72cc545afe49025539a4, 0xb712ecdCAe7C9D7CC09E17d0aFb5D3A9BD84b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a3004f092449c979df037ccf9e, 0xb7128D71a6007e0D20bE7B79c91f033bB88eb712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300b5f29f92392cad00263e71, 0xb7127500d2AF9bc26ae4BBaFE6f0C69d32b6b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a30082476e2f333f6e0357ff34, 0xb712194a06eE406E6b84b655f6759075Fc93b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300dcf541c4deaf8a0014e12f, 0xb712f924D63431d95713864768a5E93Ec28Cb712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a3001fd3fbe4b326fa03f9d415, 0xb712D910E26E9bd8a74D29D9a92832f3e430b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300fee1dd4b55c2cf03c15eb1, 0xb712734fa02e3e5C5000e5529A571f20B11Cb712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300a2411d8977e58101d5bb28, 0xb7125EB14297c3a2A00EDd56D3946fFE0d00b712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a300ba0da98e3c96c903cedfdc, 0xb71249428F83520a0686accCaC22D2D9430Ab712),
          Pair(0x0a37aec263cba0aabc09bac56a0f2074a22e69a30088c8b9a3f1eca2025e6323, 0xb7120ed0eC17BA928433395739D926Bb2938b712)
        ];

        // Test all pairs using the correct processed salt approach
        vm.startPrank(DEPLOYER);
        for (uint256 i = 0; i < pairs.length; i++) {
            // Process the salt using LibCast.hashFast like CreateX does internally for Sender variant
            bytes32 processedSalt = LibCast.hashFast(bytes32(uint256(uint160(DEPLOYER))), pairs[i].s);
            address computed = createX.computeCreate3Address(processedSalt);
            assertEq(
              computed,
              pairs[i].a,
              string(abi.encodePacked("Salt ", vm.toString(i), " address mismatch"))
            );
        }
        vm.stopPrank();
    }
}
