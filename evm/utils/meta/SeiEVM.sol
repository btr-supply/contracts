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
 * @title Sei EVM Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract SeiEvmMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "sei_evm";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7; // WSEI
        t.wgas = 0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7; // WSEI
        t.usdt = 0x9151434b16b9763660705744891fA906F660EcC5; // USDT0 aka US0
        t.usdc = 0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1;
        t.weth = 0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8;
        t.wbtc = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = address(0);
        l.gas = address(0);
        l.usdt = address(0);
        l.usdc = address(0);
        l.eth = address(0);
        l.btc = address(0);
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x2880aB155794e7179c9eE2e38200202908C17B43;
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
