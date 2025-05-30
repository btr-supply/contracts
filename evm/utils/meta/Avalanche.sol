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
 * @title Avalanche Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract AvalancheMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "avalanche";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // WAVAX
        t.wgas = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // WAVAX
        t.usdt = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; // USDT.e
        t.usdc = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // USDC.e
        t.weth = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB; // WETH.e
        t.wbtc = 0x50b7545627a5162F82A992c33b87aDc75187B218; // WBTC.e
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0x0A77230d17318075983913bC2145DB16C7366156; // AVAX
        l.gas = 0x0A77230d17318075983913bC2145DB16C7366156; // AVAX
        l.usdt = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9; // USDT/USD
        l.usdc = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a; // USDC/USD
        l.eth = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743; // ETH/USD
        l.btc = 0x976B3D034E162d8bD72D6b9C989d545b839003b0; // BTC/USD
        l.bnb = 0xBb92195Ec95DE626346eeC8282D53e261dF95241; // BNB/USD
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x4305FB66699C3B2702D4d05CF36551390A4c69C6;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
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
