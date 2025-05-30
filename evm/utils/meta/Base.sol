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
 * @title Base Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract BaseMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "base";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x4200000000000000000000000000000000000006; // WETH
        t.wgas = 0x4200000000000000000000000000000000000006; // WETH (Base's native gas token is ETH)
        t.usdt = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb; // USDT (bridged)
        t.usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC (native)
        t.weth = 0x4200000000000000000000000000000000000006;
        t.wbtc = 0x2c9171a13a29A7F1007916A057d217760e538371; // WBTC (example bridged)
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // ETH
        l.gas = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // ETH
        l.usdt = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B; // USDT/USD
        l.usdc = 0xf19d560eB8d2ADf07BD6D13ed03e1D11215721F9; // USDC/USD
        l.eth = 0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F; // ETH/USD
        l.btc = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // BTC/USD
        l.bnb = 0x4b7836916781CAAfbb7Bd1E5FDd20ED544B453b1; // BNB/USD
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D;
        a.v4PoolProvider = address(0);
    }

    function __testStables() public pure override returns (address, address) {
        return (__tokens().usdt, __tokens().usdc);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](4);
        v3[0] = UNIV3_USDT_USDC_POOL;
        v3[1] = AEROV3_USDT_USDC_POOL;
        v3[2] = CAKEV3_USDT_USDC_POOL;
        v3[3] = BASESWAP_USDT_USDC_POOL;
        v4 = new bytes32[](4);
        v4[0] = UNIV4_USDT_USDC_POOL;
        v4[1] = UNIV4_USDT_USDC_POOL2;
        v4[2] = UNIV4_USDT_USDC_POOL3;
        v4[3] = UNIV4_USDT_USDC_POOL4;
    }

    function __testVolatiles() public pure override returns (address, address) {
        // CBBTC is a constant defined in BaseChainMeta, not from __tokens().wbtc
        return (CBBTC, __tokens().weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](4);
        v3[0] = UNIV3_CBBTC_WETH_POOL;
        v3[1] = AEROV3_CBBTC_WETH_POOL;
        v3[2] = CAKEV3_CBBTC_WETH_POOL;
        v3[3] = SUSHIV3_CBBTC_WETH_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_CBBTC_WETH_POOL;
    }

    // stables
    address internal constant USDBC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address internal constant SUSDE = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2;
    address internal constant USDS = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
    address internal constant SUSDS = 0x5875eEE11Cf8398102FdAd704C9E96607675467a;
    address internal constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;
    address internal constant USD0 = 0x758a3e0b1F842C9306B783f8A4078C6C8C03a270;
    address internal constant USDX = 0xf3527ef8dE265eAa3716FB312c12847bFBA66Cef;
    address internal constant AGEUR = 0xA61BeB4A3d02decb01039e378237032B351125B4;
    address internal constant USDPLUS = 0xB79DD08EA68A908A97220C76d19A6aA9cBDE4376;
    address internal constant MIM = 0x4A3A6Dd60A34bB2Aba60D73B4C88315E9CeB6A3D;
    address internal constant DOLA = 0x4621b7A9c75199271F773Ebd9A499dbd165c3191;
    address internal constant USDZ = 0x04D5ddf5f3a8939889F11E97f8c4BB48317F1938;
    address internal constant EURC = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;

    // flagships
    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant WGAS = 0x4200000000000000000000000000000000000006;
    address internal constant WBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address internal constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    // lst/lsd
    address internal constant WSTETH = 0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452;
    address internal constant WEETH = 0x04C0599Ae5A44757c0af6F9eC3b93da8976c150A;
    address internal constant EBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address internal constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;
    address internal constant SOLVBTC = 0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f;
    address internal constant RETH = 0xB6fe221Fe9EeF5aBa221c348bA20A1Bf5e73624c;
    address internal constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address internal constant LSETH = 0xB29749498954A3A821ec37BdE86e386dF3cE30B6;
    address internal constant SUPEROETH = 0xDBFeFD2e8460a6Ee4955A68582F85708BAEA60A3;
    address internal constant RSETH = 0x1Bc71130A0e39942a7658878169764Bbd8A45993;

    // stable pools
    // usdc/usdt
    address internal constant UNIV3_USDT_USDC_POOL = 0xD56da2B74bA826f19015E6B7Dd9Dae1903E85DA1;
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x90305e6043c0879a665262237e4643df9b48c1ba51aec5abe82c5d98f0da54bd;
    bytes32 internal constant UNIV4_USDT_USDC_POOL2 = 0xe1d05fe2b899df927bc67e5eedaccb95d06bf7c769ed68469bb773615f2401f8;
    bytes32 internal constant UNIV4_USDT_USDC_POOL3 = 0xd3020570106c58635ff7f549659c4c310409c9a5d698cb826842bc8a39e3ce81;
    bytes32 internal constant UNIV4_USDT_USDC_POOL4 = 0xf13203ddbf2c9816a79b656a1a952521702715d92fea465b84ae2ed6e94a7f22;
    address internal constant AEROV3_USDT_USDC_POOL = 0xa41Bc0AFfbA7Fd420d186b84899d7ab2aC57fcD1;
    address internal constant CAKEV3_USDT_USDC_POOL = 0x5f07bb9fEE6062e9D09A52E6d587c64bAD6bA706;
    address internal constant BASESWAP_USDT_USDC_POOL = 0xe8598ada6b7A1a41f78C54a51cF15Bd2eb79A8e0;
    // usdBc/usdc
    address internal constant UNIV3_USDBC_USDC_POOL = 0x06959273E9A65433De71F5A452D529544E07dDD0;
    address internal constant AEROV3_USDBC_USDC_POOL = 0x98c7A2338336d2d354663246F64676009c7bDa97;
    address internal constant SUSHIV3_USDBC_USDC_POOL = 0xD3f749adA01aF29a713545Fb6b8E782B49A75a20;

    // volatile pools
    // weth/usdc
    address internal constant UNIV3_WETH_USDC_POOL = 0xd0b53D9277642d899DF5C87A3966A349A798F224;
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0x96d4b53a38337a5733179751781178a2613306063c511b78cd02684739288c0a;
    address internal constant AEROV3_WETH_USDC_POOL = 0xb2cc224c1c9feE385f8ad6a55b4d94E92359DC59;
    address internal constant CAKEV3_WETH_USDC_POOL = 0x72AB388E2E2F6FaceF59E3C3FA2C4E29011c2D38; // 1bp
    address internal constant CAKEV3_WETH_USDC_POOL2 = 0xB775272E537cc670C65DC852908aD47015244EaF; // 5bps
    address internal constant SUSHIV3_WETH_USDC_POOL = 0x482Fe995c4a52bc79271aB29A53591363Ee30a89; // 1pb
    address internal constant SUSHIV3_WETH_USDC_POOL2 = 0x57713F7716e0b0F65ec116912F834E49805480d2; // 5pbs
    // cbbtc/usdc
    address internal constant UNIV3_CBBTC_USDC_POOL = 0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef;
    bytes32 internal constant UNIV4_CBBTC_USDC_POOL = 0x64f978ef116d3c2e1231cfd8b80a369dcd8e91b28037c9973b65b59fd2cbbb96;
    bytes32 internal constant UNIV4_CBBTC_USDC_POOL2 =
        0x20897a5fe1b823e02fcea5fd7eeb8af75830d8352d2904b076e98692eff2e0a2;
    address internal constant AEROV3_CBBTC_USDC_POOL = 0x4e962BB3889Bf030368F56810A9c96B83CB3E778;
    address internal constant CAKEV3_CBBTC_USDC_POOL = 0xb94b22332ABf5f89877A14Cc88f2aBC48c34B3Df;
    // cbbtc/weth
    address internal constant UNIV3_CBBTC_WETH_POOL = 0x7AeA2E8A3843516afa07293a10Ac8E49906dabD1;
    bytes32 internal constant UNIV4_CBBTC_WETH_POOL = 0x2fbe93bf7177596c5d04675bdcef7bacaf98bd954dc26829fcda39f122239459;
    address internal constant AEROV3_CBBTC_WETH_POOL = 0x70aCDF2Ad0bf2402C957154f944c19Ef4e1cbAE1;
    address internal constant CAKEV3_CBBTC_WETH_POOL = 0xC211e1f853A898Bd1302385CCdE55f33a8C4B3f3;
    address internal constant SUSHIV3_CBBTC_WETH_POOL = 0x358228caAf6C235CDF982bb99E919f6e1028905b;
}
