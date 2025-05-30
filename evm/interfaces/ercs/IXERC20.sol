// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IXERC20 {
    event BridgeLimitsSet(uint256 _mintingLimit, uint256 _burningLimit, address indexed _bridge);

    error IXERC20_NotHighEnoughLimits();

    function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external;
    function mintingMaxLimitOf(address _bridge) external view returns (uint256 _limit);
    function burningMaxLimitOf(address _bridge) external view returns (uint256 _limit);
    function mintingCurrentLimitOf(address _bridge) external view returns (uint256 _limit);
    function burningCurrentLimitOf(address _bridge) external view returns (uint256 _limit);
    function mint(address _user, uint256 _amount) external;
    function burn(address _user, uint256 _amount) external;
}
