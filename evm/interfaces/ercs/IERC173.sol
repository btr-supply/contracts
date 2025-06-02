// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /// @return owner_ The address of the owner.

    function owner() external view returns (address owner_);
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}
