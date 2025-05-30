// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IERC7802 {
    event CrosschainMint(address indexed to, uint256 amount, address indexed bridge);
    event CrosschainBurn(address indexed from, uint256 amount, address indexed bridge);

    function crosschainMint(address _to, uint256 _amount) external;
    function crosschainBurn(address _from, uint256 _amount) external;
}
