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
 * @title Berachain Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract BerachainMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "berachain";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x6969696969696969696969696969696969696969; // WBERA
        t.wgas = 0x6969696969696969696969696969696969696969; // WBERA
        t.usdt = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;
        t.usdc = 0x549943e04f40284185054145c6E4e9568C1D3241; // USDC.e (Stargate)
        t.weth = 0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590;
        t.wbtc = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = address(0); // BERA
        l.gas = address(0); // BERA
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
        return (t.usdc, t.usdt != address(0) ? t.usdt : address(0));
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }

    function __testVolatiles() public pure override returns (address, address) {
        TokenMeta memory t = __tokens();
        return (t.wgas, t.weth != address(0) ? t.weth : address(0));
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }
}
