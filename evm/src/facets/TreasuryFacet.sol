// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Fees} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Treasury Facet - Manages protocol treasury funds
 * @copyright 2025
 * @notice Handles collection and distribution of protocol fees and revenues
 * @dev Manages vault fees and protocol revenue collection
- Security Sensitive: Controls fee parameters and treasury address
- Modifiers: `setAlmVaultFees`/`setDefaultFees`/`setCollector` use `onlyAdmin` or `onlyManager`. `collectFees` uses `onlyTreasury`

 * @author BTR Team
 */

contract TreasuryFacet is PermissionedFacet {
    using U for uint32;
    // --- TREASURY ---

    function initializeTreasury() external onlyAdmin {
        T.initialize(S.tres());
    }

    // --- CONFIGURATION ---

    function setCollector(address _collector) external onlyAdmin {
        T.setCollector(S.tres(), S.acc(), _collector); // Updates treasury collector address
    }

    function collector() external view returns (address) {
        return S.tres().collector;
    }

    // --- PROTOCOL FEES ---

    function validateFees(Fees memory fees) external pure {
        T.validateFees(fees); // Checks fee percentages are valid
    }

    function setDefaultFees(Fees memory fees) external onlyAdmin {
        T.setAlmVaultFees(uint32(0).vault(), fees); // Sets default fees (vault ID 0)
    }

    function defaultFees() external view returns (Fees memory) {
        return T.defaultFees(); // Returns default fee configuration
    }

    // --- ALM FEES ---

    function setAlmVaultFees(uint32 vid, Fees calldata fees) external onlyManager {
        T.setAlmVaultFees(vid.vault(), fees); // Sets fees for specific vault
    }

    function almVaultFees(uint32 vid) external view returns (Fees memory) {
        return T.almVaultFees(vid.vault()); // Returns vault-specific fees
    }

    function collectAlmFees(uint32 vid) external onlyTreasury {
        T.collectAlmFees(vid.vault(), S.tres()); // Transfers pending fees to treasury
    }
}
