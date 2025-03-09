// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BTRDiamond} from "./BTRDiamond.sol";
import {BTRVaultInit} from "./BTRVaultInit.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {ERC20Facet} from "./facets/ERC20Facet.sol";
import {ERC4626Facet} from "./facets/ERC4626Facet.sol";
import {VaultFacet} from "./facets/VaultFacet.sol";
import {AccessControlFacet} from "./facets/AccessControlFacet.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {BTRErrors as Errors, BTREvents as Events} from "./libraries/BTREvents.sol";

/// @title BTRFactory
/// @dev Factory for deploying new BTR vaults with diamond pattern
contract BTRFactory {
  // Events
  event VaultCreated(address indexed vault, address owner);
  
  // Function selectors for facets
  struct FacetSelectors {
    address facetAddress;
    bytes4[] selectors;
  }
  
  // Admin of the factory
  address public immutable admin;
  
  // Facet addresses - deployed once and shared across all vaults
  address public immutable diamondCutFacet;
  address public immutable diamondLoupeFacet;
  address public immutable erc20Facet;
  address public immutable erc4626Facet;
  address public immutable vaultFacet;
  address public immutable ownershipFacet;
  address public immutable accessControlFacet;
  
  // Cached facet cuts to avoid recomputing for each vault
  IDiamondCut.FacetCut[] private facetCuts;
  
  constructor() {
    admin = msg.sender;

    // Deploy all facets once
    diamondCutFacet = address(new DiamondCutFacet());
    diamondLoupeFacet = address(new DiamondLoupeFacet());
    erc20Facet = address(new ERC20Facet());
    erc4626Facet = address(new ERC4626Facet());
    vaultFacet = address(new VaultFacet());
    accessControlFacet = address(new AccessControlFacet());
    
    // Pre-compute facet cuts to reuse for all vaults
    facetCuts = new IDiamondCut.FacetCut[](6);
    
    // DiamondLoupeFacet
    facetCuts[0] = IDiamondCut.FacetCut({
      facetAddress: diamondLoupeFacet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: getFunctionSelectors("DiamondLoupeFacet")
    });
    
    // ERC20Facet
    facetCuts[1] = IDiamondCut.FacetCut({
      facetAddress: erc20Facet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: getFunctionSelectors("ERC20Facet")
    });
    
    // ERC4626Facet
    facetCuts[2] = IDiamondCut.FacetCut({
      facetAddress: erc4626Facet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: getFunctionSelectors("ERC4626Facet")
    });
    
    // VaultFacet
    facetCuts[3] = IDiamondCut.FacetCut({
      facetAddress: vaultFacet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: getFunctionSelectors("VaultFacet")
    });
    
    // AccessControlFacet
    facetCuts[4] = IDiamondCut.FacetCut({
      facetAddress: accessControlFacet,
      action: IDiamondCut.FacetCutAction.Add,
      functionSelectors: getFunctionSelectors("AccessControlFacet")
    });
  }
  
  /// @notice Create a new BTR Vault
  /// @param _owner Owner of the vault
  /// @param _managers Array of manager addresses
  /// @param _keepers Array of keeper addresses
  /// @return vault Address of the new vault
  function createVault(
    address _owner,
    address[] calldata _managers,
    address[] calldata _keepers
  ) external returns (address vault) {
    // Only deploy the diamond proxy, not the facets
    BTRDiamond diamond = new BTRDiamond(_owner, diamondCutFacet);
    vault = address(diamond);
    
    // Create and initialize the diamond with the pre-computed facet cuts
    BTRVaultInit vaultInit = new BTRVaultInit();
    
    // Prepare initialization data
    bytes memory initData = abi.encodeWithSelector(
      BTRVaultInit.init.selector,
      _managers,
      _keepers
    );
    
    // Call diamondCut to add the pre-deployed facets
    DiamondCutFacet(vault).diamondCut(facetCuts, address(vaultInit), initData);
    
    emit VaultCreated(vault, _owner);
  }
  
  // Helper to get function selectors - calculated once per facet
  function getFunctionSelectors(string memory _facetName) internal pure returns (bytes4[] memory) {
    if (keccak256(bytes(_facetName)) == keccak256(bytes("DiamondLoupeFacet"))) {
      bytes4[] memory selectors = new bytes4[](5);
      selectors[0] = bytes4(keccak256("facets()"));
      selectors[1] = bytes4(keccak256("facetFunctionSelectors(address)"));
      selectors[2] = bytes4(keccak256("facetAddresses()"));
      selectors[3] = bytes4(keccak256("facetAddress(bytes4)"));
      selectors[4] = bytes4(keccak256("supportsInterface(bytes4)"));
      return selectors;
    } 
    else if (keccak256(bytes(_facetName)) == keccak256(bytes("ERC20Facet"))) {
      bytes4[] memory selectors = new bytes4[](9);
      selectors[0] = bytes4(keccak256("name()"));
      selectors[1] = bytes4(keccak256("symbol()"));
      selectors[2] = bytes4(keccak256("decimals()"));
      selectors[3] = bytes4(keccak256("totalSupply()"));
      selectors[4] = bytes4(keccak256("balanceOf(address)"));
      selectors[5] = bytes4(keccak256("transfer(address,uint256)"));
      selectors[6] = bytes4(keccak256("allowance(address,address)"));
      selectors[7] = bytes4(keccak256("approve(address,uint256)"));
      selectors[8] = bytes4(keccak256("transferFrom(address,address,uint256)"));
      return selectors;
    }
    else if (keccak256(bytes(_facetName)) == keccak256(bytes("ERC4626Facet"))) {
      bytes4[] memory selectors = new bytes4[](14);
      selectors[0] = bytes4(keccak256("asset()"));
      selectors[1] = bytes4(keccak256("totalAssets()"));
      selectors[2] = bytes4(keccak256("convertToShares(uint256)"));
      selectors[3] = bytes4(keccak256("convertToAssets(uint256)"));
      selectors[4] = bytes4(keccak256("maxDeposit(address)"));
      selectors[5] = bytes4(keccak256("previewDeposit(uint256)"));
      selectors[6] = bytes4(keccak256("deposit(uint256,address)"));
      selectors[7] = bytes4(keccak256("maxMint(address)"));
      selectors[8] = bytes4(keccak256("previewMint(uint256)"));
      selectors[9] = bytes4(keccak256("mint(uint256,address)"));
      selectors[10] = bytes4(keccak256("maxWithdraw(address)"));
      selectors[11] = bytes4(keccak256("previewWithdraw(uint256)"));
      selectors[12] = bytes4(keccak256("withdraw(uint256,address,address)"));
      selectors[13] = bytes4(keccak256("redeem(uint256,address,address)"));
      return selectors;
    }
    else if (keccak256(bytes(_facetName)) == keccak256(bytes("VaultFacet"))) {
      // Only a subset shown for brevity
      bytes4[] memory selectors = new bytes4[](5);
      selectors[0] = bytes4(keccak256("initialize(string,string,address,address,uint256,uint256,uint16,uint256)"));
      selectors[1] = bytes4(keccak256("rebalance((address[],address[]))"));
      selectors[2] = bytes4(keccak256("setfeeBps(uint16)"));
      selectors[3] = bytes4(keccak256("pause()"));
      selectors[4] = bytes4(keccak256("unpause()"));
      return selectors;
    }
    else if (keccak256(bytes(_facetName)) == keccak256(bytes("OwnershipFacet"))) {
      bytes4[] memory selectors = new bytes4[](2);
      selectors[0] = bytes4(keccak256("owner()"));
      selectors[1] = bytes4(keccak256("transferOwnership(address)"));
      return selectors;
    }
    else if (keccak256(bytes(_facetName)) == keccak256(bytes("AccessControlFacet"))) {
      bytes4[] memory selectors = new bytes4[](8);
      selectors[0] = bytes4(keccak256("hasRole(bytes32,address)"));
      selectors[1] = bytes4(keccak256("getRoleAdmin(bytes32)"));
      selectors[2] = bytes4(keccak256("setRoleAdmin(bytes32,bytes32)"));
      selectors[3] = bytes4(keccak256("grantRole(bytes32,address)"));
      selectors[4] = bytes4(keccak256("acceptRole(bytes32)"));
      selectors[5] = bytes4(keccak256("cancelRoleGrant(bytes32,address)"));
      selectors[6] = bytes4(keccak256("revokeRole(bytes32,address)"));
      selectors[7] = bytes4(keccak256("setTimelockConfig(uint256,uint256)"));
      return selectors;
    }
    
    revert Errors.InvalidFacetName();
  }
} 