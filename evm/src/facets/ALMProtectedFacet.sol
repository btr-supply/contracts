// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {
    DEX,
    VaultInitParams,
    RebalanceParams,
    RebalancePrep,
    ErrorType,
    ALMVault,
    Range,
    RangeParams,
    RebalanceProceeds,
    BurnProceeds
} from "@/BTRTypes.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibALMProtected as ALMP} from "@libraries/LibALMProtected.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {LibManagement as M} from "@libraries/LibManagement.sol";
import {LibPausable as P} from "@libraries/LibPausable.sol";
import {NonReentrantFacet} from "@facets/abstract/NonReentrantFacet.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";
import {RestrictedFacet} from "@facets/abstract/RestrictedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Protected Facet - ALM privileged operations
 * @copyright 2025
 * @notice Handles initialization, vault creation, pool registration, range management, and vault upkeep operations
 * @dev Sub-facet for ALM privileged operations:
- Functions: `createVault`, `setDexAdapter`, `setPoolInfo`, `setWeights`, `zeroOutWeights`, `pauseAlmVault`, `unpauseAlmVault`, `restrictMint`, `rebalance`, `burnRanges`, `mintRanges`, `remintRanges`, `prepareRebalance`, `previewBurnRanges`
- Modifiers: `onlyAdmin` for `createVault`; `onlyManager` for `setPoolInfo`, `setDexAdapter`, `setWeights`, `zeroOutWeights`, `pauseAlmVault`, `unpauseAlmVault`, `restrictMint`; `onlyKeeper` for `rebalance`, `burnRanges`, `mintRanges`, `remintRanges`
 * @author BTR Team
 */

contract ALMProtectedFacet is PermissionedFacet {
    using U for uint32;
    using P for uint32;
    using M for uint32;
    using LibERC1155 for uint32;
    using ALMP for ALMVault;

    // --- POOL CONFIGURATION ---

    function setPoolInfo(
        bytes32 _poolId,
        address _adapter,
        address _token0,
        address _token1,
        uint24 _tickSize,
        uint32 _fee
    ) external onlyManager {
        ALMP.setPoolInfo(S.reg(), _poolId, _adapter, _token0, _token1, _tickSize, _fee);
    }

    // /*
    //  * @param _poolId Unique identifier for the pool
    //  */
    // function removePool(bytes32 _poolId) external onlyManager {
    //   ALMP.removePool(_poolId);
    // }

    function setDexAdapter(address _oldAdapter, address _newAdapter) external onlyManager {
        ALMP.setDexAdapter(_oldAdapter, _newAdapter, S.reg());
    }

    // --- RANGE CONFIGURATION ---

    function setWeights(uint32 _vid, uint16[] calldata _weights) external onlyManager {
        ALMP.setWeights(_vid.vault(), S.reg(), _weights);
    }

    function zeroOutWeights(uint32 _vid) external onlyManager {
        ALMP.zeroOutWeights(_vid.vault(), S.reg());
    }

    // --- VAULT CONFIGURATION ---

    function createVault(VaultInitParams calldata _params) external onlyAdmin returns (uint32 vid) {
        vid = ALMP.createVault(S.reg(), _params);
    }

    function pauseAlmVault(uint32 _vid) external onlyManager {
        P.pauseAlmVault(_vid.vault());
    }

    function unpauseAlmVault(uint32 _vid) external onlyManager {
        P.unpauseAlmVault(_vid.vault());
    }

    function setMaxSupply(uint32 _vid, uint256 _maxSupply) external onlyManager {
        LibERC1155.setMaxSupply(_vid.vault(), _maxSupply);
    }

    function restrictMint(uint32 _vid, bool _restricted) external onlyManager {
        ALMP.restrictMint(_vid.vault(), _restricted);
    }

    // --- VAULT UPKEEP ---

    function rebalance(uint32 _vid, RebalanceParams calldata _rebalanceData)
        external
        onlyKeeper
        returns (uint256 protocolFee0, uint256 protocolFee1)
    {
        RebalanceProceeds memory proceeds = ALMP.rebalance(_vid.vault(), S.reg(), S.rst(), _rebalanceData);
        return (proceeds.protocolFee0, proceeds.protocolFee1);
    }

    function burnRanges(uint32 _vid)
        external
        onlyKeeper
        returns (uint256 recovered0, uint256 recovered1, uint256 totalLpFee0, uint256 totalLpFee1)
    {
        BurnProceeds memory result = ALMB.burnRanges(_vid.vault(), S.reg(), true);
        return (result.recovered0, result.recovered1, result.lpFee0, result.lpFee1);
    }

    function mintRanges(uint32 _vid, RebalanceParams calldata _rebalanceData)
        external
        onlyKeeper
        returns (uint256 totalSpent0, uint256 totalSpent1)
    {
        (totalSpent0, totalSpent1) = ALMP.mintRanges(_vid.vault(), S.reg(), _rebalanceData);
    }

    function remintRanges(uint32 _vid) external onlyKeeper returns (uint256 totalSpent0, uint256 totalSpent1) {
        (totalSpent0, totalSpent1) = ALMP.remintRanges(_vid.vault(), S.reg());
    }

    function prepareRebalance(uint32 _vid, RangeParams[] calldata _ranges)
        external
        view
        returns (RebalancePrep memory prep, uint256 fee0, uint256 fee1)
    {
        prep = ALMP.prepareRebalance(_vid.vault(), S.reg(), _ranges);
        return (prep, prep.fee0, prep.fee1);
    }

    function previewBurnRanges(uint32 _vid)
        external
        view
        returns (uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1)
    {
        return ALMP.previewBurnRanges(_vid.vault(), S.reg());
    }
}
