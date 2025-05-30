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
 * @title Ethereum Metadata
 * @copyright 2025
 * @author BTR Team
 */

abstract contract EthereumMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "ethereum";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        t.wgas = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
        t.usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        t.usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        t.weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        t.wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        t.bnb = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        l.wgas = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        l.usdt = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        l.usdc = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
        l.eth = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        l.btc = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
        l.bnb = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
        a.v4PoolProvider = address(0);
    }

    function __testStables() public pure override returns (address, address) {
        return (__tokens().usdt, __tokens().usdc);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](4);
        v3[0] = UNIV3_USDT_USDC_POOL;
        v3[1] = SOLIDLYV3_USDT_USDC_POOL;
        v3[2] = SUSHIV3_USDT_USDC_POOL;
        v3[3] = CAKEV3_USDT_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_USDT_USDC_POOL;
    }

    function __testVolatiles() public pure override returns (address, address) {
        return (__tokens().weth, __tokens().usdc);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](5);
        v3[0] = UNIV3_WETH_USDC_POOL;
        v3[1] = UNIV3_WETH_USDC_POOL2;
        v3[2] = UNIV3_WETH_USDC_POOL3;
        v3[3] = CAKEV3_WETH_USDC_POOL;
        v3[4] = SUSHIV3_WETH_USDC_POOL;
        v4 = new bytes32[](1);
        v4[0] = UNIV4_WETH_USDC_POOL;
    }

    // stables

    address internal constant FRXUSD = 0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29;
    address internal constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address internal constant SFRAX = 0xA663B02CF0a4b149d2aD41910CB81e23e1c41c32;
    address internal constant FDUSD = 0xc5f0f7b66764F6ec8C8Dff7BA683102295E16409;
    address internal constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address internal constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address internal constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address internal constant SDOLA = 0xb45ad160634c528Cc3D2926d9807104FA3157305;
    address internal constant CRVUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address internal constant SCRVUSD = 0x0655977FEb2f289A4aB78af67BAB0d17aAb84367;
    address internal constant USDE = 0x4c9EDD5852cd905f086C759E8383e09bff1E68B3;
    address internal constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    address internal constant PYUSD = 0x6c3ea9036406852006290770BEdFcAbA0e23A0e8;
    address internal constant USDD = 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6;
    address internal constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address internal constant USDP = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address internal constant BUIDL = 0x7712c34205737192402172409a8F7ccef8aA2AEc;
    address internal constant USD0 = 0x73A15FeD60Bf67631dC6cd7Bc5B6e8da8190aCF5;
    address internal constant USDX = 0xf3527ef8dE265eAa3716FB312c12847bFBA66Cef;
    address internal constant USR = 0x66a1E37c9b0eAddca17d3662D6c05F4DECf3e110;
    address internal constant USDY = 0x96F6eF951840721AdBF46Ac996b59E0235CB985C;
    address internal constant RLUSD = 0x8292Bb45bf1Ee4d140127049757C2E0fF06317eD;
    address internal constant USDA = 0x8A60E489004Ca22d775C5F2c657598278d17D9c2;
    address internal constant SUSDA = 0x2B66AAdE1e9C062FF411bd47C44E0Ad696d43BD9;
    address internal constant DEUSD = 0x15700B564Ca08D9439C58cA5053166E8317aa138;
    address internal constant SDEUSD = 0x5C5b196aBE0d54485975D1Ec29617D42D9198326;
    address internal constant EURC = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;

    // flagships
    address internal constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
    address internal constant WSOL = 0xD31a59c85aE9D8edEFeC411D448f90841571b89c;
    address internal constant WAVAX = 0x85f138bfEE4ef8e540890CFb48F620571d67Eda3;
    address internal constant BNB = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    address internal constant ARB = 0xB50721BCf8d664c30412Cfbc6cf7a15145234ad1;
    address internal constant POL = 0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6;
    address internal constant TON = 0x582d872A1B094FC48F5DE31D3B73F2D9bE47def1;
    address internal constant DOT = 0x21c2c96Dbfa137E23946143c71AC8330F9B44001;
    address internal constant MNTL = 0x3c3a81e81dc49A522A592e7622A7E711c06bf354;
    address internal constant MOVE = 0x3073f7aAA4DB83f95e9FFf17424F71D4751a3073;
    address internal constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;

    // lst/lsd
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address internal constant WEETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
    address internal constant RSETH = 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7;
    address internal constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address internal constant SOLVBTCBBN = 0xd9D920AA40f578ab794426F5C90F6C731D159DEf;
    address internal constant METH = 0xd5F7838F5C461fefF7FE49ea5ebaF7728bB0ADfa;
    address internal constant CMETH = 0xE6829d9a7eE3040e1276Fa75293Bde931859e8fA;
    address internal constant OSETH = 0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38;
    address internal constant EETH = 0x35fA164735182de50811E8e2E824cFb9B6118ac2;
    address internal constant EBTC = 0x657e8C867D8B37dCC18fA4Caead9C45EB088C642;
    address internal constant ETHX = 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b;
    address internal constant CBETH = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address internal constant WBETH = 0xa2E3356610840701BDf5611a53974510Ae27E2e1;
    address internal constant STBTC = 0xf6718b2701D4a6498eF77D7c152b2137Ab28b8A3;
    address internal constant OETH = 0x856c4Efb76C1D1AE02e20CEB03A2A6a08b0b8dC3;
    address internal constant RSWETH = 0xFAe103DC9cf190eD75350761e95403b7b8aFa6c0;

    // stable pools
    // usdt/usdc
    address internal constant UNIV3_USDT_USDC_POOL = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6; // 1bp
    bytes32 internal constant UNIV4_USDT_USDC_POOL = 0x8aa4e11cbdf30eedc92100f4c8a31ff748e201d44712cc8c90d189edaa8e4e47;
    address internal constant SOLIDLYV3_USDT_USDC_POOL = 0x6146be494fee4C73540cB1c5F87536aBF1452500;
    address internal constant SUSHIV3_USDT_USDC_POOL = 0xfA6e8E97ecECDC36302eCA534f63439b1E79487B;
    address internal constant CAKEV3_USDT_USDC_POOL = 0x04c8577958CcC170EB3d2CCa76F9d51bc6E42D8f;

    // volatile pools
    // weth/usdc
    address internal constant UNIV3_WETH_USDC_POOL = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8; // 30bps
    address internal constant UNIV3_WETH_USDC_POOL2 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // 5bps
    address internal constant UNIV3_WETH_USDC_POOL3 = 0xE0554a476A092703abdB3Ef35c80e0D76d32939F; // 1bp
    bytes32 internal constant UNIV4_WETH_USDC_POOL = 0x21c67e77068de97969ba93d4aab21826d33ca12bb9f565d8496e8fda8a82ca27;
    address internal constant CAKEV3_WETH_USDC_POOL = 0x1ac1A8FEaAEa1900C4166dEeed0C11cC10669D36;
    address internal constant SUSHIV3_WETH_USDC_POOL = 0x397FF1542f962076d0BFE58eA045FfA2d347ACa0;
    // wbtc/usdc
    address internal constant UNIV3_WBTC_USDC_POOL = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35; // 30bps
    address internal constant UNIV3_WBTC_USDC_POOL2 = 0x9a772018FbD77fcD2d25657e5C547BAfF3Fd7D16; // 5bps
    address internal constant UNIV3_WBTC_USDC_POOL3 = 0x56534741CD8B152df6d48AdF7ac51f75169A83b2;
    bytes32 internal constant UNIV4_WBTC_USDC_POOL = 0xb98437c7ba28c6590dd4e1cc46aa89eed181f97108e5b6221730d41347bc817f;
    bytes32 internal constant UNIV4_WBTC_USDC_POOL2 = 0x3ea74c37fbb79dfcd6d760870f0f4e00cf4c3960b3259d0d43f211c0547394c1;
    // wbtc/weth
    address internal constant UNIV3_WBTC_WETH_POOL = 0x4585FE77225b41b697C938B018E2Ac67Ac5a20c0;
    bytes32 internal constant UNIV4_WBTC_WETH_POOL = 0x54c72c46df32f2cc455e84e41e191b26ed73a29452cdd3d82f511097af9f427e;
    address internal constant SUSHIV3_WBTC_WETH_POOL = 0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58;
}
