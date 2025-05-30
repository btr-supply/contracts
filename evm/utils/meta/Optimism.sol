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
 * @title Optimism Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract OptimismMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "optimism";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x4200000000000000000000000000000000000042; // OP
        t.wgas = 0x4200000000000000000000000000000000000006; // WETH
        t.usdt = 0x01bFF41798a0BcF287b996046Ca68b395DbC1071;
        t.usdc = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85; // Native USDC
        t.weth = 0x4200000000000000000000000000000000000006;
        t.wbtc = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x0D276FC14719f9292D5C1eA2198673d1f4269246; // OP/USD
        l.wgas = 0x0D276FC14719f9292D5C1eA2198673d1f4269246; // OP/USD
        l.usdt = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3; // USDT/USD
        l.usdc = 0xECef79E109e997bCA29c1c0897ec9d7b03647F5E; // USDC/USD (for native USDC)
        l.eth = 0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593; // ETH/USD
        l.btc = 0x13e3Ee699D1909E989722E753853AE30b17e08c5; // BTC/USD
        l.bnb = 0xD38579f7cBD14c22cF1997575eA8eF7bfe62ca2c; // BNB/USD
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xff1a0f4744e8582DF1aE09D5611b887B6a12925C;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
        a.v4PoolProvider = address(0);
    }

    function __testStables() public pure override returns (address, address) {
        return (__tokens().usdt, __tokens().usdc);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](4);
        v3[0] = UNIV3_USDT_USDC_POOL;
        v3[1] = VELOV3_USDT_USDC_POOL;
        v3[2] = SOLIDLYV3_USDT_USDC_POOL;
        v3[3] = SUSHIV3_USDT_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_USDT_USDC_POOL;
    }

    function __testVolatiles() public pure override returns (address, address) {
        return (__tokens().wbtc, __tokens().weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](4);
        v3[0] = UNIV3_WBTC_WETH_POOL;
        v3[1] = UNIV3_WBTC_WETH_POOL2;
        v3[2] = VELOV3_WBTC_WETH_POOL;
        v3[3] = SUSHIV3_WBTC_WETH_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_WBTC_WETH_POOL;
    }

    // stables
    address internal constant AXLUSDC = 0xEB466342C4d449BC9f53A865D5Cb90586f405215;
    address internal constant FRXUSD = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant FRAX = 0x2E3D870790dC77A83DD1d18184Acc7439A53f475;
    address internal constant LUSD = 0xc40F949F8a4e094D1b49a23ea9241D289B7b2819;
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address internal constant BUSD = 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39;
    address internal constant DOLA = 0x8aE125E8653821E851F12A49F7765db9a9ce7384;
    address internal constant CRVUSD = 0xC52D7F23a2e460248Db6eE192Cb23dD12bDDCbf6;
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address internal constant SUSDE = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2;
    address internal constant USDD = 0x7113370218f31764C1B6353BDF6004d86fF6B9cc;
    address internal constant TUSD = 0xcB59a0A753fDB7491d5F3D794316F1adE197B21E;
    address internal constant SUSD = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;
    address internal constant USDPLUS = 0x73cb180bf0521828d8849bc8CF2B920918e23032;
    address internal constant BUIDL = 0xa1CDAb15bBA75a80dF4089CaFbA013e376957cF5;

    // flagships
    address internal constant TBTC = 0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40;
    address internal constant WSOL = 0xba1Cf949c382A32a09A17B2AdF3587fc7fA664f1;
    address internal constant OP = 0x4200000000000000000000000000000000000042;
    address internal constant WLD = 0xdC6fF44d5d932Cbd77B52E5612Ba0529DC6226F1;

    // lst/lsd
    address internal constant STETH = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
    address internal constant WSTETH = 0x1F32b1c2345538c0c6f582fCB022739c4A194Ebb;
    address internal constant RETH = 0x9Bcef72be871e61ED4fBbc7630889beE758eb81D;
    address internal constant FRXETH = 0x6806411765Af15Bddd26f8f544A34cC40cb9838B;
    address internal constant SFRXETH = 0x484c2D6e3cDd945a8B2DF735e079178C1036578c;
    address internal constant SETH = 0xE405de8F52ba7559f9df3C368500B6E6ae6Cee49;
    address internal constant SBTC = 0x298B9B95708152ff6968aafd889c6586e9169f1D;
    address internal constant CBETH = 0xadDb6A0412DE1BA0F936DCaeb8Aaa24578dcF3B2;

    // stable pools
    // usdt/usdc
    address internal constant UNIV3_USDT_USDC_POOL = 0xA73C628eaf6e283E26A7b1f8001CF186aa4c0E8E;
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x83dfcb7b726c634c35776adb25f22ff54cd62e25593af523371fc22f3b4e7a2c;
    address internal constant VELOV3_USDT_USDC_POOL = 0x84Ce89B4f6F67E523A81A82f9f2F14D84B726F6B;
    address internal constant SOLIDLYV3_USDT_USDC_POOL = 0x4DBb2D7785654074c53c5A915126d3378446bd61;
    address internal constant SUSHIV3_USDT_USDC_POOL = 0x962E23cd3F58f887a5238082A75d223f71890629;

    // volatile pools
    // weth/usdc
    address internal constant UNIV3_WETH_USDC_POOL = 0x1fb3cf6e48F1E7B10213E7b6d87D4c073C7Fdb7b; // 5bps
    address internal constant UNIV3_WETH_USDC_POOL2 = 0xc1738D90E2E26C35784A0d3E3d8A9f795074bcA4; // 30bps
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0x51bf4cc5b8d9f7f759e41f572fe2a25bc2aeb42432bf12544a350595e5c8bb43;
    address internal constant VELOV3_WETH_USDC_POOL = 0x478946BcD4a5a22b316470F5486fAfb928C0bA25;
    address internal constant SUSHIV3_WETH_USDC_POOL = 0x146EDa2f1D35efb5eEf5703aCeC701c68E1503d8;
    // wbtc/usdc
    address internal constant UNIV3_WBTC_USDC_POOL = 0xaDAb76dD2dcA7aE080A796F0ce86170e482AfB4a;
    bytes32 internal constant UNIV4_WBTC_USDC_POOL = 0x933abc8000f132b89e40cb40a988e8692fa7e0f3229e28c6729f794b7eed99f6;
    // wbtc/weth
    address internal constant UNIV3_WBTC_WETH_POOL = 0x85C31FFA3706d1cce9d525a00f1C7D4A2911754c; // 5bps
    address internal constant UNIV3_WBTC_WETH_POOL2 = 0x73B14a78a0D396C521f954532d43fd5fFe385216; // 30bps
    bytes32 internal constant UNIV4_WBTC_WETH_POOL = 0x5876423ef0d34b53e8ca5d6972ff9a9d72261eacf645a2fad664450f3eebc003;
    address internal constant VELOV3_WBTC_WETH_POOL = 0x319C0DD36284ac24A6b2beE73929f699b9f48c38;
    address internal constant SUSHIV3_WBTC_WETH_POOL = 0x689A850F62B41d89B5e5C3465Cd291374B215813;
}
