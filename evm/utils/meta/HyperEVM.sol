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
 * @title HyperEVM Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract HyperEvmMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "hyper_evm";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x5555555555555555555555555555555555555555; // WHYPE
        t.wgas = 0x5555555555555555555555555555555555555555; // WHYPE
        t.usdt = 0xB8CE59FC3717ada4C02eaDF9682A9e934F625ebb; // USDT0
        t.usdc = 0x02c6a2fA58cC01A18B8D9E00eA48d65E4dF26c70; // feUSD
        t.weth = 0xBe6727B535545C67d5cAa73dEa54865B92CF7907; // UETH (Unit ETH)
        t.wbtc = 0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463; // UBTC (Unit BTC)
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.usdt = address(0);
        l.usdc = address(0);
        l.eth = address(0);
        l.btc = address(0);
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xe9d69CdD6Fe41e7B621B4A688C5D1a68cB5c8ADc;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = address(0);
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
