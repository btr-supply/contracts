// evm/interfaces/IERC173.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IERC173 {
  /// @notice Get the address of the owner
  /// @return owner_ The address of the owner
  function owner() external view returns (address owner_);

  /// @notice Set the address of the new owner of the contract
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;

  /// @notice Emitted when ownership of contract changes
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
