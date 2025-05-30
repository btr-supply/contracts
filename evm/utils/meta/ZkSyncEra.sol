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
 * @title zkSync Era Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract ZkSyncEraMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "zksync_era";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E; // ZK
        t.wgas = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91; // WETH
        t.usdt = 0x493257fD37EDB34451f62EDf8D2a0C418852bA4C;
        t.usdc = 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4;
        t.weth = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91;
        t.wbtc = 0xBBeB516fb02a01611cBBE0453Fe3c580D7281011;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0xD1ce60dc8AE060DDD17cA8716C96f193bC88DD13; // ZK/USD
        l.gas = 0x6D41d1dc818112880b40e26BD6FD347E41008eDA; // ETH/USD
        l.usdt = 0xB615075979AE1836B476F651f1eB79f0Cd3956a9; // USDT/USD
        l.usdc = 0x1824D297C6d6D311A204495277B63e943C2D376E; // USDC/USD
        l.eth = 0x6D41d1dc818112880b40e26BD6FD347E41008eDA; // ETH/USD
        l.btc = 0x4Cba285c15e3B540C474A114a7b135193e4f1EA6; // BTC/USD
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xf087c864AEccFb6A2Bf1Af6A0382B0d0f6c5D834;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x2A3948BB219D6B2Fa83D64100006391a96bE6cb7;
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
}
