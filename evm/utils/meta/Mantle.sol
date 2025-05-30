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
 * @title Mantle Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract MantleMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "mantle";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; // WMNT
        t.wgas = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8; // WMNT
        t.usdt = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
        t.usdc = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;
        t.weth = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
        t.wbtc = 0xCAbAE6f6Ea1ecaB08Ad02fE02ce9A44F09aebfA2;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0xD97F20bEbeD74e8144134C4b148fE93417dd0F96; // MNT/USD
        l.gas = 0xD97F20bEbeD74e8144134C4b148fE93417dd0F96; // MNT/USD
        l.usdt = 0xd86048D5e4fe96157CE03Ae519A9045bEDaa6551;
        l.usdc = 0x22b422CECb0D4Bd5afF3EA999b048FA17F5263bD;
        l.eth = 0x5bc7Cf88EB131DB18b5d7930e793095140799aD5;
        l.btc = 0x7db2275279F52D0914A481e14c4Ce5a59705A25b;
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x2390836290AD7D96e587537579d807cea68181a8;
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
        return (t.wgas, t.weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }
}
