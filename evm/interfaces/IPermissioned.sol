// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IPermissioned {
    // Role constants
    function ADMIN_ROLE() external view returns (bytes32);
    function MANAGER_ROLE() external view returns (bytes32);
    function KEEPER_ROLE() external view returns (bytes32);
    function TREASURY_ROLE() external view returns (bytes32);
    // Role checking functions
    function hasRole(bytes32 _role, address _account) external view returns (bool);
    function checkRole(bytes32 _role) external view;
    function checkRole(bytes32 _role, address _account) external view;

    // Convenience role functions
    function isDiamond(address _account) external view returns (bool);
    function isAdmin(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);
    function isKeeper(address _account) external view returns (bool);
    function isTreasury(address _account) external view returns (bool);

    // Role member accessor functions
    function diamond() external view returns (address);
    function admin() external view returns (address);
    function treasury() external view returns (address);
    function managers() external view returns (address[] memory);
    function keepers() external view returns (address[] memory);

    // Blacklist functions
    function isBlacklisted(address _account) external view returns (bool);
    function isWhitelisted(address _account) external view returns (bool);
}
