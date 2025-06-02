// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "./abstract/ERC20Bridgeable.sol";
import "@interfaces/IBTR.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Main Contract (Placeholder) - Placeholder for potential core logic
 * @copyright 2025
 * @notice Currently serves as a placeholder or entry point, may be removed or expanded
 * @dev Defines basic contract structure, potentially for non-diamond parts
 * @author BTR Team
 */

contract BTR is ERC20Bridgeable {
    error InvalidMaxSupply();
    error GenesisAlreadyMinted();
    error NoTreasuryFound();
    error InvalidAmount();
    // Custom Events
    event GenesisMint(address indexed _treasury, uint256 _amount);

    event MaxSupplyUpdated(uint256 _newMaxSupply);
    // Supply limits

    uint256 public maxSupply;
    bool public genesisMinted;

    constructor(string memory _name, string memory _symbol, address _diamond, uint256 _maxSupply)
        ERC20Bridgeable(_name, _symbol, _diamond)
    {
        genesisMinted = false;
        _setMaxSupply(_maxSupply);
    }

    function _checkTreasury() internal view returns (address tres) {
        tres = diamond.treasury();
        if (tres == address(0)) revert NoTreasuryFound();
    }

    function _supplyFits(uint256 _amount) internal view override returns (bool) {
        return totalSupply() + _amount > maxSupply;
    }

    function _checkMaxSupply(uint256 _amount) internal view {
        if (_supplyFits(_amount)) revert MaxSupplyExceeded();
    }

    function _setMaxSupply(uint256 _maxSupply) internal {
        if (_maxSupply == 0) revert InvalidMaxSupply();
        if (_maxSupply < totalSupply()) revert InvalidMaxSupply();
        maxSupply = _maxSupply;
        emit MaxSupplyUpdated(_maxSupply);
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyAdmin {
        _setMaxSupply(_newMaxSupply);
    }

    function mintGenesis(uint256 _amount) external onlyAdmin {
        if (genesisMinted) revert GenesisAlreadyMinted();
        if (_amount == 0) revert InvalidAmount();
        _checkMaxSupply(_amount);

        address tres = _checkTreasury();
        _mint(tres, _amount);
        genesisMinted = true;
        emit GenesisMint(tres, _amount);
    }

    function mintToTreasury(uint256 _amount) external onlyAdmin {
        if (_amount == 0) revert InvalidAmount();
        _checkMaxSupply(_amount);
        _mint(_checkTreasury(), _amount);
    }
}
