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
 * @title Arbitrum One Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract ArbitrumOneMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "arbitrum_one";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x912CE59144191C1204E64559FE8253a0e49E6548; // ARB
        t.wgas = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // WETH (Arbitrum's native gas token is ETH)
        t.usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // USDT.e
        t.usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        t.weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        t.wbtc = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6; // ARB/USD
        l.gas = 0x6ce185860a4963106506C203335A2910413708e9; // ETH/USD
        l.usdt = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3; // USDT/USD
        l.usdc = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7; // USDC/USD
        l.eth = 0x6ce185860a4963106506C203335A2910413708e9; // ETH/USD
        l.btc = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612; // BTC/USD
        l.bnb = 0x6970460aabF80C5BE983C6b74e5D06dEDCA95D4A; // BNB/USD
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
        v3 = new address[](5);
        v3[0] = UNIV3_USDT_USDC_POOL;
        v3[1] = CAMELOTV3_USDT_USDC_POOL;
        v3[2] = SUSHIV3_USDT_USDC_POOL;
        v3[3] = CAKEV3_USDT_USDC_POOL;
        v3[4] = RAMSESV3_USDT_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_USDT_USDC_POOL;
    }

    function __testVolatiles() public pure override returns (address, address) {
        return (__tokens().wbtc, __tokens().weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](5);
        v3[0] = UNIV3_WBTC_WETH_POOL;
        v3[1] = UNIV3_WBTC_WETH_POOL2;
        v3[2] = CAMELOTV3_WBTC_WETH_POOL;
        v3[3] = CAKEV3_WBTC_WETH_POOL;
        v3[4] = RAMSESV3_WBTC_WETH_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_WBTC_WETH_POOL;
    }

    // stables
    address internal constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant FRXUSD = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant FRAX = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;
    address internal constant USDS = 0x6491c05A82219b8D1479057361ff1654749b876b;
    address internal constant SUSDS = 0xdDb46999F8891663a8F2828d25298f70416d7610;
    address internal constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address internal constant SUSDE = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2;
    address internal constant TUSD = 0x4D15a3A2286D883AF0AA1B3f21367843FAc63E07;
    address internal constant USDD = 0x680447595e8b7b3Aa1B43beB9f6098C79ac2Ab3f;
    address internal constant AGEUR = 0xFA5Ed56A203466CbBC2430a43c66b9D8723528E7;
    address internal constant MAI = 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d;
    address internal constant USDX = 0xf3527ef8dE265eAa3716FB312c12847bFBA66Cef;
    address internal constant SUSDX = 0x7788A3538C5fc7F9c7C8A74EAC4c898fC8d87d92;
    address internal constant USD0 = 0x35f1C5cB7Fb977E669fD244C567Da99d8a3a6850;
    address internal constant USD0PP = 0x2B65F9d2e4B84a2dF6ff0525741b75d1276a9C2F;
    address internal constant EURC = 0xaDDfd192daA492b772EA5c180e79570dEC92fF5c;
    address internal constant BUIDL = 0xA6525Ae43eDCd03dC08E775774dCAbd3bb925872;
    address internal constant USDY = 0x35e050d3C0eC2d29D269a8EcEa763a183bDF9A9D;
    address internal constant GHO = 0x7dfF72693f6A4149b17e7C6314655f6A9F7c8B33;
    address internal constant USDL = 0x7F850b0aB1988Dd17B69aC564c1E2857949e4dEe;
    address internal constant DOLA = 0x6A7661795C374c0bFC635934efAddFf3A7Ee23b6;

    // flagships
    address internal constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address internal constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address internal constant TBTC = 0x6c84a8f1c29108F47a79964b5Fe888D4f4D0dE40;
    address internal constant GNO = 0xa0b862F60edEf4452F25B4160F177db44DeB6Cf1;

    // lst/lsd
    address internal constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address internal constant FRXETH = 0x178412e79c25968a32e89b11f63B33F733770c2A;
    address internal constant SFRXETH = 0x95aB45875cFFdba1E5f451B950bC2E42c0053f39;
    address internal constant SOLVBTCENA = 0xaFAfd68AFe3fe65d376eEC9Eab1802616cFacCb8;
    address internal constant SOLVBTC = 0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0;
    address internal constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address internal constant WEETH = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe;
    address internal constant EBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address internal constant STBTC = 0xf6718b2701D4a6498eF77D7c152b2137Ab28b8A3;
    address internal constant RETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

    // stable pools
    // usdt/usdc
    address internal constant UNIV3_USDT_USDC_POOL = 0xbE3aD6a5669Dc0B8b12FeBC03608860C31E2eef6;
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x20354cf3a44f2980f9fd205b7ed4418fee7ebf82a925c7d3c5d1565eb9831484;
    address internal constant CAMELOTV3_USDT_USDC_POOL = 0xa17aFCAb059F3C6751F5B64347b5a503C3291868;
    address internal constant SUSHIV3_USDT_USDC_POOL = 0xD1E1Ac29B31B35646EaBD77163E212b76fE3b6A2;
    address internal constant CAKEV3_USDT_USDC_POOL = 0x7e928afb59f5dE9D2f4d162f754C6eB40c88aA8E;
    address internal constant RAMSESV3_USDT_USDC_POOL = 0xdf63268Af25A2A69c07d09A88336Cd9424269a1f;

    // volatile pools
    // weth/usdc
    address internal constant UNIV3_WETH_USDC_POOL = 0xC6962004f452bE9203591991D15f6b388e09E8D0; // 5bps
    address internal constant UNIV3_WETH_USDC_POOL2 = 0x6f38e884725a116C9C7fBF208e79FE8828a2595F; // 1bp
    address internal constant UNIV3_WETH_USDC_POOL3 = 0xc473e2aEE3441BF9240Be85eb122aBB059A3B57c; // 30bps
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0x03df2300e83353309c1069ae3ea89c31b361a009f9c36a1de5c8f0afcc45bde8; // 30bps
    bytes32 internal constant UNIV4_WETH_USDC_POOL2 = 0x864abca0a6202dba5b8868772308da953ff125b0f95015adbf89aaf579e903a8; // 5bps
    address internal constant CAMELOTV3_WETH_USDC_POOL = 0xB1026b8e7276e7AC75410F1fcbbe21796e8f7526;
    address internal constant CAKEV3_WETH_USDC_POOL = 0x7fCDC35463E3770c2fB992716Cd070B63540b947; // 1bp
    address internal constant CAKEV3_WETH_USDC_POOL2 = 0xd9e2a1a61B6E61b275cEc326465d417e52C1b95c; // 5bps
    address internal constant RAMSESV3_WETH_USDC_POOL = 0x30AFBcF9458c3131A6d051C621E307E6278E4110;
    address internal constant JOEV2_WETH_USDC_POOL = 0x69f1216cB2905bf0852f74624D5Fa7b5FC4dA710;
    address internal constant SUSHIV3_WETH_USDC_POOL = 0xf3Eb87C1F6020982173C908E7eB31aA66c1f0296;

    // wbtc/usdc
    address internal constant UNIV3_WBTC_USDC_POOL = 0x0E4831319A50228B9e450861297aB92dee15B44F;
    bytes32 internal constant UNIV4_WBTC_USDC_POOL = 0x70bf44c3a9b6b047bf60e5a05968225dbf3d6a5b9e8a95a73727e48921e889c1; // 30bps
    bytes32 internal constant UNIV4_WBTC_USDC_POOL2 = 0x80c735c5a0222241f211b3edb8df2ccefad94553ec18f1c29143f0399c78f500; // 5bps
    address internal constant CAKEV3_WBTC_USDC_POOL = 0x843aC8dc6D34AEB07a56812b8b36429eE46BDd07; // 5bps
    address internal constant CAKEV3_WBTC_USDC_POOL2 = 0x5A17cbf5F866BDe11C28861a2742764Fac0Eba4B; // 1bp
    address internal constant SUSHIV3_WBTC_USDC_POOL = 0x699f628A8A1DE0f28cf9181C1F8ED848eBB0BBdF;

    // wbtc/weth
    address internal constant UNIV3_WBTC_WETH_POOL = 0x2f5e87C9312fa29aed5c179E456625D79015299c; // 5bps
    address internal constant UNIV3_WBTC_WETH_POOL2 = 0x149e36E72726e0BceA5c59d40df2c43F60f5A22D; // 30bps
    bytes32 internal constant UNIV4_WBTC_WETH_POOL = 0x8b3781471ab98774c59775df9cc505ce20b36afffd297aef2dc17daafce3b140; // 5bps
    address internal constant CAMELOTV3_WBTC_WETH_POOL = 0xd845f7D4f4DeB9Ff5bCf09D140Ef13718F6f6C71;
    address internal constant CAKEV3_WBTC_WETH_POOL = 0x4bfc22A4dA7f31F8a912a79A7e44a822398b4390;
    address internal constant RAMSESV3_WBTC_WETH_POOL = 0x2760cC828B2e4D04f8eC261A5335426bb22d9291;
}
