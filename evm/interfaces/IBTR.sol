// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./IERC20Bridgeable.sol";

interface IBTR is IERC20Bridgeable {
    // Supply management
    function maxSupply() external view returns (uint256);
    function genesisMinted() external view returns (bool);
    function setMaxSupply(uint256 _newMaxSupply) external;
    function mintGenesis(uint256 _amount) external;
    function mintToTreasury(uint256 _amount) external;
    // Events

    event MaxSupplyUpdated(uint256 _newMaxSupply);
    event GenesisMint(address indexed _treasury, uint256 _amount);
}
