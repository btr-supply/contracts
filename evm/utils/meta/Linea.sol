// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./__ChainMeta.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Linea Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract LineaMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "linea";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f; // WETH
        t.wgas = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f; // WETH
        t.usdt = 0xA219439258ca9da29E9Cc4cE5596924745e12B93;
        t.usdc = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;
        t.weth = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
        t.wbtc = 0x3aAB2285ddcDdaD8edf438C1bAB47e1a9D05a9b4;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA; // ETH
        l.gas = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA; // ETH
        l.usdt = 0xefCA2bbe0EdD0E22b2e0d2F8248E99F4bEf4A7dB;
        l.usdc = 0xAADAa473C1bDF7317ec07c915680Af29DeBfdCb5;
        l.eth = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        l.btc = 0x7A99092816C8BD5ec8ba229e3a6E6Da1E628E1F9;
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x89502c3731F69DDC95B65753708A07F8Cd0373F4;
        a.v4PoolProvider = address(0);
    }

    function __testStables() public pure override returns (address, address) {
        TokenMeta memory t = __tokens();
        return (t.usdc, t.usdt);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }

    function __testVolatiles() public pure override returns (address, address) {
        TokenMeta memory t = __tokens();
        return (t.wgas, t.weth); // WETH (wgas) and WETH itself
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }

    address internal constant SUSHIV3_WETH_USDC_POOL = 0x7077f0CFF76077D0ebb335B607DB574400510557;
}
