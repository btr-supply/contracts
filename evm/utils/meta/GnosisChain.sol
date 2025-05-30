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
 * @title Gnosis Chain Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract GnosisChainMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "gnosis_chain";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb; // GNO
        t.wgas = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d; // WXDAI
        t.usdt = 0x4ECaBa5870353805a9F068101A40E0f32ed605C6;
        t.usdc = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;
        t.weth = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;
        t.wbtc = 0x8e5bBbb09Ed1ebdE8674Cda39A0c169401db4252;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x22441d81416430A54336aB28765abd31a792Ad37; // GNO/USD
        l.gas = 0x678df3415fc31947dA4324eC63212874be5a82f8; // DAI/USD
        l.usdt = 0x68811D7DF835B1c33e6EEae8E7C141eF48d48cc7;
        l.usdc = 0x26C31ac71010aF62E6B486D1132E266D6298857D;
        l.eth = 0xa767f745331D267c7751297D982b050c93985627;
        l.btc = 0x6C1d7e76EF7304a40e8456ce883BC56d3dEA3F7d;
        l.bnb = 0x6D42cc26756C34F26BEcDD9b30a279cE9Ea8296E;
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x2880aB155794e7179c9eE2e38200202908C17B43;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x36616cf17557639614c1cdDb356b1B83fc0B2132;
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
    address internal constant USDCE = 0x2a22f9c3b484c3629090FeED35F17Ff8F88f76F0;
    address internal constant GYD = 0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8;
    address internal constant sDAI = 0xaf204776c7245bF4147c2612BF6e5972Ee483701;
    address internal constant EURe = 0x420CA0f9B9b604cE0fd9C18EF134C705e5Fa3430;
    address internal constant WXDAI = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;

    // flagships
    address internal constant GNO = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;

    // lst/lsd
    address internal constant WSTETH = 0x6C76971f98945AE98dD7d4DFcA8711ebea946eA6;
    address internal constant RETH = 0xc791240D1F2dEf5938E2031364Ff4ed887133C3d;

    // stable pools
    address internal constant SUSHIV3_GNO_WXDAI_POOL = 0x9eA52f774E21ff2fd4DD452160D612C764d21581;

    // volatile pools
}
