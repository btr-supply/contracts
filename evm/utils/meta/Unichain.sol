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
 * @title Unichain Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract UnichainMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "unichain";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x8f187aA05619a017077f5308904739877ce9eA21; // UNI
        t.wgas = 0x4200000000000000000000000000000000000006; // WETH
        t.usdt = 0x9151434b16b9763660705744891fA906F660EcC5; // USDT0 aka USD0
        t.usdc = 0x078D782b760474a361dDA0AF3839290b0EF57AD6;
        t.weth = 0x0000000000000000000000000000000000000000;
        t.wbtc = 0x927B51f251480a681271180DA4de28D44EC4AfB8;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = address(0); // UNI/USD
        l.gas = 0xd9c93081210dFc33326B2af4C2c11848095E6a9a; // ETH/USD
        l.usdt = 0xd391fB4c7D0B88dc44530E785246112388AFA98F; // USDT/USD
        l.usdc = 0x25DdD2fEd0d51fe79d292Da47dd9f10AbdB4b3EC; // USDC/USD
        l.eth = 0xd9c93081210dFc33326B2af4C2c11848095E6a9a; // ETH/USD
        l.btc = 0x2AF69319fACBbc1ad77d56538B35c1f9FFe86dEF; // BTC/USD
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

    // stables

    // flagships

    // lst/lsd

    // stable pools
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x77ea9d2be50eb3e82b62db928a1bcc573064dd2a14f5026847e755518c8659c9;
    bytes32 internal constant UNIV4_EZETH_WETH_POOL = 0xc36db4be4a3bfded1a98dc1017b01db62f34aa02c92c6febeb277c87a6152ee8;
    bytes32 internal constant UNIV4_WSTETH_WETH_POOL =
        0xd10d359f50ba8d1e0b6c30974a65bf06895fba4bf2b692b2c75d987d3b6b863d;
    bytes32 internal constant UNIV4_WEETH_WETH_POOL = 0xbb1e92b6f31285d432d9f9462ebc4a003dfe26d9bc47d44543a12d457f1d22f1;
    bytes32 internal constant UNIV4_RSETH_WETH_POOL = 0x88cdc69f6be00de0b69f92de9ae0c4621fb6a3cdba582804010b182238c98dde;

    // volatile pools
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0x8aa4e11cbdf30eedc92100f4c8a31ff748e201d44712cc8c90d189edaa8e4e47;
    bytes32 internal constant UNIV4_WETH_USDT_POOL = 0x04b7dd024db64cfbe325191c818266e4776918cd9eaf021c26949a859e654b16;
    bytes32 internal constant UNIV4_WBTC_USDT_POOL = 0xc349e9692b4afe1bcfdd6fadaf9ff0df2a2bea8c1a3e56323b57be08e4b8df6a;
    bytes32 internal constant UNIV4_WBTC_WETH_POOL = 0x764afe9ab22a5c80882918bb4e59b954912b17a22c3524c68a8cf08f7386e08f;
    bytes32 internal constant UNIV4_WBTC_USDC_POOL = 0x53b06f1bb8b622cc4b7dbd9bc9f4a34788034bc48702cd2af4135b48444d5b24;
}
