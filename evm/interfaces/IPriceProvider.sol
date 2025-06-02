// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IOracleAdapter} from "./IOracleAdapter.sol";

interface IPriceProvider is IOracleAdapter {
    // --- PRICE CONVERSION ---
    function toUsdBp(address _asset) external view returns (uint256);
    function fromUsdBp(address _asset) external view returns (uint256);
    function toUsd(address _asset, uint256 _amount) external view returns (uint256);
    function fromUsd(address _asset, uint256 _amount) external view returns (uint256);
    function convert(address _base, address _quote, uint256 _amount) external view returns (uint256);
    function exchangeRate(address _base, address _quote) external view returns (uint256);
    function exchangeRateBp(address _base, address _quote) external view returns (uint256);

    // --- PARAM STRUCTS ---
    struct ChainlinkParams {
        bytes32[] feeds; // token addresses
        bytes32[] providerIds; // aggregator V3 addresses
        uint256[] ttls;
    }

    struct PythParams {
        address pyth; // aggregator address
        bytes32[] feeds; // token addresses
        bytes32[] providerIds; // provider feed ids
        uint256[] ttls;
    }
}
