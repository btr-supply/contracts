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
 * @title Abstract Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract AbstractMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "abstract";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x000000000000000000000000000000000000800A; // WETH (waiting for ABS)
        t.wgas = 0x000000000000000000000000000000000000800A; // WETH (Arbitrum's native gas token is ETH)
        t.usdt = 0x6386dA73545ae4E2B2E0393688fA8B65Bb9a7169;
        t.usdc = 0x84A71ccD554Cc1b02749b35d22F684CC8ec987e1; // USDC.e (Stargate)
        t.weth = 0x000000000000000000000000000000000000800A;
        t.wbtc = address(0); // waiting for WBTC/WBTC.e
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = address(0);
        l.gas = address(0);
        l.usdt = address(0);
        l.usdc = address(0);
        l.eth = address(0);
        l.btc = address(0);
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x8739d5024B5143278E2b15Bd9e7C26f6CEc658F1;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = address(0);
        a.v4PoolProvider = address(0);
    }

    function __testStables() public pure override returns (address, address) {
        return (__tokens().usdt, __tokens().usdc);
    }

    function __testStablePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](0);
        v4 = new bytes32[](0);
    }

    function __testVolatiles() public pure override returns (address, address) {
        return (__tokens().wbtc, __tokens().weth);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        v3 = new address[](0);
        v4 = new bytes32[](0);
    }
}
