// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {CoreAddresses} from "@/BTRTypes.sol";

interface IOracle {
    function initializeOracle(CoreAddresses memory _tokens) external;
    function twapLookback(bytes32 _feed) external view returns (uint32);
    function defaultTwapLookback() external view returns (uint32);
    function maxDeviation(bytes32 _feed) external view returns (uint256);
    function defaultMaxDeviation() external view returns (uint256);
    function provider(bytes32 _feed) external view returns (address);
    function hasFeed(bytes32 _feed) external view returns (bool);
    function setFeed(bytes32 _feed, address _provider, bytes32 _providerId, uint256 _ttl) external;
    function removeFeed(bytes32 _feed) external;
    function setProvider(address _provider, address _replacing, bytes calldata _params) external;
    function setProvider(address _provider, bytes calldata _params) external;
    function removeProvider(address _provider) external;
    function setAlt(address _provider, address _alt) external;
    function removeAlt(address _provider) external;
    function setDefaultTwapLookback(uint32 _lookback) external;
    function setTwapLookback(bytes32 _feed, uint32 _lookback) external;
    function setDefaultMaxDeviation(uint256 _maxDeviationBp) external;
    function setMaxDeviation(bytes32 _feed, uint256 _maxDeviationBp) external;
}
