// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ICamelotYieldBooster {
    function MAX_TOTAL_ALLOCATION_FLOOR() external view returns (uint256);
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocateAllFromPool(address userAddress, uint256 tokenId) external;
    function emergencyWithdraw(address token) external;
    function forceDeallocate() external;
    function forcedDeallocationStatus() external view returns (bool);
    function getExpectedMultiplier(
        uint256 maxBoostMultiplier,
        uint256 lpAmount,
        uint256 totalLpSupply,
        uint256 userAllocation,
        uint256 poolTotalAllocation
    ) external view returns (uint256);
    function getMultiplier(
        address pool,
        uint256 maxBoostMultiplier,
        uint256 lpAmount,
        uint256 totalLpSupply,
        uint256 userAllocation
    ) external view returns (uint256);
    function getPoolTotalAllocations(address pool) external view returns (uint256);
    function getUserPosition(address userAddress, address pool, uint256 index) external view returns (uint256);
    function getUserPositionAllocations(address userAddress, address pool, uint256 tokenId)
        external
        view
        returns (uint256);
    function getUserPositionsLength(address userAddress, address pool) external view returns (uint256);
    function getUserTotalAllocations(address userAddress) external view returns (uint256);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function setTotalAllocationFloor(uint256 floor) external;
    function totalAllocations() external view returns (uint256);
    function totalAllocationFloor() external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function updateForcedDeallocationStatus(bool status) external;
    function usersPositionsAllocations(address, address, uint256) external view returns (uint256);
    function xGrailToken() external view returns (address);
}
