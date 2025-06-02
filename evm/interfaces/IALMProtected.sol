// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {VaultInitParams} from "@/BTRTypes.sol";

interface IALMProtected {
    function setDexAdapter(address _oldAdapter, address _newAdapter) external;
    function setWeights(uint32 _vid, uint16[] calldata _weights) external;
    function zeroOutWeights(uint32 _vid) external;
    function createVault(VaultInitParams calldata _params) external returns (uint32 vid);
    function pauseAlmVault(uint32 _vid) external;
    function unpauseAlmVault(uint32 _vid) external;
    function setMaxSupply(uint32 _vid, uint256 _maxSupply) external;
    function restrictMint(uint32 _vid, bool _restricted) external;
}
