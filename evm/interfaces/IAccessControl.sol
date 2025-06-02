// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {PendingAcceptance} from "@/BTRTypes.sol";

interface IAccessControl {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
    function members(bytes32 _role) external view returns (address[] memory);
    function timelockConfig() external view returns (uint256 grantDelay, uint256 acceptanceTtl);
    function checkRoleAcceptance(PendingAcceptance calldata _acceptance, bytes32 _role) external view;
    function initializeAccessControl() external;
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;
    function setTimelockConfig(uint256 _grantDelay, uint256 _acceptanceTtl) external;
    function grantRole(bytes32 _role, address _account) external;
    function revokeRole(bytes32 _role, address _account) external;
    function renounceRole(bytes32 _role) external;
    function acceptRole(bytes32 _role) external;
    function cancelRoleGrant(address _account) external;
    function revokeAll(bytes32 _role) external;
    function revokeAllManagers() external;
    function revokeAllKeepers() external;
}
