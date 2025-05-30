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
 * @title BNB Chain Metadata
 * @copyright 2025
 * @author BTR Team
 */

abstract contract BnbChainMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "bnb_chain";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
        t.wgas = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
        t.usdt = 0x55d398326f99059fF775485246999027B3197955;
        t.usdc = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        t.weth = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
        t.wbtc = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
        t.bnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB
        l.wgas = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB
        l.usdt = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320;
        l.usdc = 0x51597f405303C4377E36123cBc172b13269EA163;
        l.eth = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
        l.btc = 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;
        l.bnb = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x4D7E825f80bDf85e913E0DD2A2D54927e9dE1594;
    }

    function __aave() public pure override returns (AaveMeta memory) {
        return AaveMeta({v3PoolProvider: 0xff75B6da14FfbbfD355Daf7a2731456b3562Ba6D, v4PoolProvider: address(0)});
    }

    function __testStables() public pure override returns (address, address) {
        return (__tokens().usdt, __tokens().usdc);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](5);
        v3[0] = UNIV3_USDT_USDC_POOL;
        v3[1] = THENAV3_USDT_USDC_POOL;
        v3[2] = CAKEV3_USDT_USDC_POOL;
        v3[3] = CAKEV3_USDT_USDC_POOL2;
        v3[4] = SQUADV3_USDT_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_USDT_USDC_POOL;
    }

    function __testVolatiles() public pure override returns (address, address) {
        // Assuming BTCB and WBNB are primary volatile test tokens for BNBChain
        return ( /*__tokens().wbtc*/ BTCB, /*__tokens().wgas*/ WBNB);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](5);
        v3[0] = UNIV3_BTCB_WBNB_POOL;
        v3[1] = CAKEV3_BTCB_WBNB_POOL;
        v3[2] = CAKEV3_BTCB_WBNB_POOL2;
        v3[3] = THENAV3_BTCB_WBNB_POOL;
        v3[4] = SQUADV3_BTCB_WBNB_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_BTCB_WBNB_POOL;
    }
    // stables

    address internal constant FRXUSD = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant FRAX = 0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40;
    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant FDUSD = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409;
    address internal constant LISUSD = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
    address internal constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address internal constant USDE = 0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34;
    address internal constant SUSDE = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2;
    address internal constant USD0 = 0x758a3e0b1F842C9306B783f8A4078C6C8C03a270;
    address internal constant CRVUSD = 0xe2fb3F127f5450DeE44afe054385d74C392BdeF4;
    address internal constant USDX = 0xf3527ef8dE265eAa3716FB312c12847bFBA66Cef;
    address internal constant SUSDX = 0x7788A3538C5fc7F9c7C8A74EAC4c898fC8d87d92;
    address internal constant TUSD = 0x40af3827F39D0EAcBF4A168f8D4ee67c121D11c9;
    address internal constant USDD = 0x392004BEe213F1FF580C867359C246924f21E6Ad;
    address internal constant USDPLUS = 0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65;
    address internal constant MAI = 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d;

    // flagships
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address internal constant XRP = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;
    address internal constant DOGE = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;
    address internal constant ADA = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
    address internal constant WGAS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant WTON = 0x76A797A59Ba2C17726896976B7B3747BfD1d220f;
    address internal constant AVAX = 0x1CE0c2827e2eF14D5C4f29a091d735A204794041;
    address internal constant POL = 0xCC42724C6683B7E57334c4E856f4c9965ED682bD;
    address internal constant DOT = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
    address internal constant LTC = 0x4338665CBB7B2485A8855A139b75D5e34AB0DB94;
    address internal constant BCH = 0x8fF795a6F4D97E7887C79beA79aba5cc76444aDf;
    address internal constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address internal constant LBTC = 0xecAc9C5F704e954931349Da37F60E39f515c11c1;
    address internal constant ARB = 0xa050FFb3eEb8200eEB7F61ce34FF644420FD3522;
    address internal constant OP = 0x170C84E3b1D282f9628229836086716141995200;

    // lst/lsd
    address internal constant SOLVBTC = 0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7;
    address internal constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address internal constant frxETH = 0x64048A7eEcF3a2F1BA9e144aAc3D7dB6e58F555e;
    address internal constant SOLVBTCCORE = 0xb9f59cAB0d6AA9D711acE5c3640003Bc09C15Faf;
    // address internal constant SOLVBTC = 0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0; // Duplicate
    // address internal constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5; // Duplicate
    address internal constant WEETH = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe;
    address internal constant EBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address internal constant STBTC = 0xf6718b2701D4a6498eF77D7c152b2137Ab28b8A3;
    address internal constant RETH = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

    // stable pools
    // usdt/usdc
    address internal constant UNIV3_USDT_USDC_POOL = 0x2C3c320D49019D4f9A92352e947c7e5AcFE47D68; // 1bp
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x89676efcfab64c52ae3ad0d38bc7c524fc195d6e697fc4890478e5e9f623a727;
    address internal constant CAKEV3_USDT_USDC_POOL = 0x92b7807bF19b7DDdf89b706143896d05228f3121; // 1bp
    address internal constant CAKEV3_USDT_USDC_POOL2 = 0x4f31Fa980a675570939B737Ebdde0471a4Be40Eb; // 5bps
    address internal constant THENAV3_USDT_USDC_POOL = 0x1b9a1120a17617D8eC4dC80B921A9A1C50Caef7d;
    address internal constant SQUADV3_USDT_USDC_POOL = 0xEfcB55270c5fe85FC8EB6a311dc5Aa9479839F0D;

    // volatile pools
    // btc/usdt
    address internal constant UNIV3_BTCB_USDT_POOL = 0x813c0decbB1097fFF46d0Ed6a39fB5f6a83043f4;
    bytes32 internal constant UNIV4_BTCB_USDT_POOL = 0xee47ca9aa3dc46e1f16b0198e82de6dd66c555a5d71577c78b6fb6d5ccbaf5c1;
    address internal constant CAKEV3_BTCB_USDT_POOL = 0x46Cf1cF8c69595804ba91dFdd8d6b960c9B0a7C4; // 5bps
    address internal constant CAKEV3_BTCB_USDT_POOL2 = 0x247f51881d1E3aE0f759AFB801413a6C948Ef442; // 1bp
    // bnb/usdt
    address internal constant UNIV3_WBNB_USDT_POOL = 0x47a90A2d92A8367A91EfA1906bFc8c1E05bf10c4; // 1bp
    address internal constant UNIV3_WBNB_USDT_POOL2 = 0x7862D9B4bE2156B15d54F41ee4EDE2d5b0b455e4; // 30bps
    bytes32 internal constant UNIV4_WBNB_USDT_POOL = 0xa77d89e40ddd6a57b72ad4a8c55554b2fd6171026c903462a9f9c7be133811a6;
    // btcb/wbnb
    address internal constant UNIV3_BTCB_WBNB_POOL = 0x28dF0835942396B7a1b7aE1cd068728E6ddBbAfD;
    bytes32 internal constant UNIV4_BTCB_WBNB_POOL = 0xc197357b0f65a134cf443d8fbbd77b3070861514a9eb3f9162620a6452d1b59f;
    address internal constant CAKEV3_BTCB_WBNB_POOL = 0x6bbc40579ad1BBD243895cA0ACB086BB6300d636; // 5bps
    address internal constant CAKEV3_BTCB_WBNB_POOL2 = 0x62Edaf2a56c9FB55be5F9B1399Ac067f6a37013b; // 1bp
    address internal constant THENAV3_BTCB_WBNB_POOL = 0x6B67112aa7b45E8CdC0a93B8D66A6A36e68ae8e5;
    address internal constant SQUADV3_BTCB_WBNB_POOL = 0x606D6F19081fe3dB277c3400cDBfED2eA0534955;
    // weth/wbnb
    address internal constant UNIV3_WBNB_WETH_POOL = 0x0f338Ec12d3f7C3D77A4B9fcC1f95F3FB6AD0EA6;
    bytes32 internal constant UNIV4_WBNB_WETH_POOL = 0x5c9d98ef4ee6363dc69b5aacfb6c6b26385fc11f1dd5b093d7dac35ea53a5315;
    address internal constant CAKEV3_WBNB_WETH_POOL = 0x62Fcb3C1794FB95BD8B1A97f6Ad5D8a7e4943a1e;
    address internal constant THENAV3_WBNB_WETH_POOL = 0x1123E75b71019962CD4d21b0F3018a6412eDb63C;
    address internal constant SQUADV3_WBNB_WETH_POOL = 0xb6Bb744FB59fa399D09f67Ae3634942F533B577f;
    // weth/btcb
    address internal constant UNIV3_WETH_BTCB_POOL = 0x3Fb2623567E21F8C50F0Ae86f54EF4849b4eb47b;
    address internal constant CAKEV3_WETH_BTCB_POOL = 0x4BBA1018b967e59220b22Ca03f68821A3276c9a6; // 5bps
    address internal constant CAKEV3_WETH_BTCB_POOL2 = 0xCEc31052610aaf0693D6B4d34E055687af3AeeE6; // 1bp
    address internal constant CAKEV3_WETH_BTCB_POOL3 = 0xD4dCA84E1808da3354924cD243c66828cf775470; // 25bps
    address internal constant THENAV3_WETH_BTCB_POOL = 0x1F9B1A3DdeDBf47b96C65F29c0586b678DE2623b; // 1bp
}
