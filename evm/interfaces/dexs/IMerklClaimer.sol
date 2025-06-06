// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IMerklClaimer {
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external;
}
