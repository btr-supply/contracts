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
 * @title Scroll Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract ScrollMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "scroll";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xd29687c813D741E2F938F4aC377128810E217b1b; // SCR
        t.wgas = 0x5300000000000000000000000000000000000004; // WETH
        t.usdt = 0xf55BEC9cafDbE8730f096Aa55dad6D22d44099Df t.usdc = 0x06eFdBFf2a14a7c8E15944D1F4A48F9F95F663A4;
        t.weth = 0x5300000000000000000000000000000000000004;
        t.wbtc = 0x3C1BCa5a656e69edCD0D4E36BEbb3FcDAcA60Cf1;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x26f6F7C468EE309115d19Aa2055db5A74F8cE7A5; // SCR/USD
        l.gas = 0x6bF14CB0A831078629D993FDeBcB182b21A8774C; // ETH/USD
        l.usdt = 0xf376A91Ae078927eb3686D6010a6f1482424954E; // USDT/USD
        l.usdc = 0x43d12Fb3AfCAd5347fA764EeAB105478337b7200; // USDC/USD
        l.eth = 0x6bF14CB0A831078629D993FDeBcB182b21A8774C; // ETH/USD
        l.btc = 0xCaca6BFdeDA537236Ee406437D2F8a400026C589; // BTC/USD
        l.bnb = 0x1AC823FdC79c30b1aB1787FF5e5766D6f29235E1; // BNB/USD
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x69850D0B276776781C063771b161bd8894BCdD04;
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
        return (t.wgas, t.weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }
}
