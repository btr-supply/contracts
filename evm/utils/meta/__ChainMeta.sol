// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {LibCast} from "@libraries/LibCast.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Chain Metadata Base - Base contract for chain-specific constants
 * @copyright 2025
 * @notice Provides base functionality for chain metadata contracts
 * @dev Extended by specific chain metadata contracts
 * @author BTR Team
 */

struct TokenMeta {
    address gov;
    address wgas;
    address usdt;
    address usdc;
    address weth;
    address wbtc;
    address bnb;
}

struct ChainlinkMeta {
    address gas; // eg. ETH/BNB/ETH/ETH/XDAI etc.
    address gov; // eg. ETH/BNB/ARB/OP/GNO etc.
    address usdt;
    address usdc;
    address eth;
    address btc;
    address bnb;
}

struct PythMeta {
    address provider;
    bytes32 usdt;
    bytes32 usdc;
    bytes32 eth;
    bytes32 btc;
    bytes32 bnb;
}

struct AaveMeta {
    address v3PoolProvider;
    address v4PoolProvider; // Though always address(0) in current data, good to have for future
}

abstract contract __ChainMeta {
    function __id() public pure virtual returns (string memory);
    function __tokens() public pure virtual returns (TokenMeta memory);
    function __link() public pure virtual returns (ChainlinkMeta memory);

    function __pyth() public pure virtual returns (PythMeta memory) {
        return PythMeta({
            provider: 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729,
            usdt: 0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a,
            usdc: 0x2b89b9dc8fdf9f34709a5b106b472f0f39bb6ca9ce04b0fd7f2e971688e2e53b,
            eth: 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43,
            btc: 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace,
            bnb: 0x2f95862b045670cd22bee3114c39763a4a08beeb663b145d283c31d7d1101c4f
        });
    }

    function __testLinkProviderParams() public pure virtual returns (IPriceProvider.ChainlinkParams memory p) {
        ChainlinkMeta memory l = __link();
        TokenMeta memory t = __tokens();
        (p.feeds, p.providerIds, p.ttls) = (new bytes32[](4), new bytes32[](4), new uint256[](4));
        (p.feeds[0], p.providerIds[0], p.ttls[0]) = (LibCast.toBytes32(t.usdc), LibCast.toBytes32(l.usdc), 1 days);
        (p.feeds[1], p.providerIds[1], p.ttls[1]) = (LibCast.toBytes32(t.usdt), LibCast.toBytes32(l.usdt), 1 days);
        (p.feeds[2], p.providerIds[2], p.ttls[2]) = (LibCast.toBytes32(t.weth), LibCast.toBytes32(l.eth), 1 days);
        (p.feeds[3], p.providerIds[3], p.ttls[3]) = (LibCast.toBytes32(t.wbtc), LibCast.toBytes32(l.btc), 1 days);
        // (p.feeds[4], p.providerIds[4], p.ttls[4]) = (LibCast.toBytes32(t.bnb), l.bnb, 1 days);
    }

    function __testPythProviderParams() public pure virtual returns (IPriceProvider.PythParams memory p) {
        PythMeta memory pyth = __pyth();
        TokenMeta memory t = __tokens();
        p.pyth = pyth.provider;
        (p.feeds, p.providerIds, p.ttls) = (new bytes32[](4), new bytes32[](4), new uint256[](4));
        (p.feeds[0], p.providerIds[0], p.ttls[0]) = (LibCast.toBytes32(t.usdc), pyth.usdc, 1 days);
        (p.feeds[1], p.providerIds[1], p.ttls[1]) = (LibCast.toBytes32(t.usdt), pyth.usdt, 1 days);
        (p.feeds[2], p.providerIds[2], p.ttls[2]) = (LibCast.toBytes32(t.weth), pyth.eth, 1 days);
        (p.feeds[3], p.providerIds[3], p.ttls[3]) = (LibCast.toBytes32(t.wbtc), pyth.btc, 1 days);
    }

    function __aave() public pure virtual returns (AaveMeta memory);
    function __testStables() public pure virtual returns (address, address);
    function __testStablePools() public pure virtual returns (address[] memory v3, bytes32[] memory v4);
    function __testVolatiles() public pure virtual returns (address, address);
    function __testVolatilePools() public pure virtual returns (address[] memory v3, bytes32[] memory v4);
}
