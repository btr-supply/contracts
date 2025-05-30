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
 * @title Polygon Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract PolygonMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "polygon";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC aka WPOL
        t.wgas = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC aka WPOL
        t.usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT.e
        t.usdc = 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359;
        t.weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        t.wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
        t.bnb = 0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3;
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // POL/USD
        l.gas = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // POL/USD
        l.usdt = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7; // USDT/USD
        l.usdc = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDC/USD
        l.eth = 0xc907E116054Ad103354f2D350FD2514433D57F6f; // ETH/USD
        l.btc = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // BTC/USD
        l.bnb = 0x82a6c4AF830caa6c97bb504425f6A66165C2c26e; // BNB/USD
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
        v3 = new address[](3);
        v3[0] = UNIV3_USDC_USDT_POOL;
        v3[1] = QUICKV3_USDC_USDT_POOL;
        v3[2] = SUSHIV3_USDT_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_USDC_USDT_POOL;
    }

    function __testVolatiles() public pure override returns (address, address) {
        return (__tokens().wbtc, __tokens().weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](2);
        v3[0] = UNIV3_WBTC_WETH_POOL;
        v3[1] = QUICKV3_WBTC_WETH_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_WBTC_WETH_POOL;
    }

    // stables
    address internal constant USDCE = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address internal constant BUIDL = 0x2893Ef551B6dD69F661Ac00F11D93E5Dc5Dc0e99;

    // flagships
    address internal constant WPOL = 0x0000000000000000000000000000000000001010;
    address internal constant WBNB = 0x3BA4c387f786bFEE076A58914F5Bd38d668B42c3;

    // lst/lsd
    address internal constant RETH = 0x0266F4F08D82372CF0FcbCCc0Ff74309089c74d1;

    // stable pools
    address internal constant UNIV3_USDC_USDT_POOL = 0x31083a78E11B18e450fd139F9ABEa98CD53181B7; // 1bp
    bytes32 internal constant UNIV4_USDC_USDT_POOL = 0x8d1b5f8da63fa29b191672231d3845740a11fcbef6c76e077cfffe56cc27c707;
    address internal constant QUICKV3_USDC_USDT_POOL = 0x0e3Eb2C75Bd7dD0e12249d96b1321d9570764D77; // .1bp
    address internal constant SUSHIV3_USDT_USDC_POOL = 0x498d5cdcC5667b21210b49442Bf2D8792527194d;

    // volatile pools
    // weth/usdc
    address internal constant UNIV3_WETH_USDC_POOL = 0xA4D8c89f0c20efbe54cBa9e7e7a7E509056228D9; // 5bps
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0xdb26d6f2af41f431d447f292d9d96950f3d3a86cdfc321673301d029412502a1;
    address internal constant QUICKV3_WETH_USDC_POOL = 0xa6AeDF7c4Ed6e821E67a6BfD56FD1702aD9a9719; // 4bps
    // wbtc/usdc
    address internal constant UNIV3_WBTC_USDC_POOL = 0x32FAE204835e08b9374493d6B4628FD1F87DD045; // 5pbs
    bytes32 internal constant UNIV4_WBTC_USDC_POOL = 0xcb43e7be737de625e6799cd593d9ec2c1285a64261dc715ea1bdcd42735f6cbc;
    address internal constant QUICKV3_WBTC_USDC_POOL = 0xdb975b96828352880409e86d5aE93c23c924f812; // 5pbs
    // wpol/usdc
    address internal constant UNIV3_WPOL_USDC_POOL = 0xB6e57ed85c4c9dbfEF2a68711e9d6f36c56e0FcB; // 5bps
    address internal constant UNIV3_WPOL_USDC_POOL2 = 0x2DB87C4831B2fec2E35591221455834193b50D1B; // 30bps
    bytes32 internal constant UNIV4_WPOL_USDC_POOL = 0x81d3c57932bb451b60029c9e60832e00a220af4a14c15f829b9090b3fd5717f2;
    address internal constant QUICKV3_WPOL_USDC_POOL = 0x6669B4706cC152F359e947BCa68E263A87c52634; // 10pbs
    // wbtc/weth
    address internal constant UNIV3_WBTC_WETH_POOL = 0x50eaEDB835021E4A108B7290636d62E9765cc6d7; // 5pbs
    bytes32 internal constant UNIV4_WBTC_WETH_POOL = 0x6826ff7e51df3bb57ba65a9ec1296a6074abce905f26b2e2917dc3f0bd9a88b9;
    address internal constant QUICKV3_WBTC_WETH_POOL = 0xAC4494e30a85369e332BDB5230d6d694d4259DbC; // 4pbs
}
