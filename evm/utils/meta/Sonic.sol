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
 * @title Sonic Metadata
 * @copyright 2025
 * @author BTR Team
 */

contract SonicMeta is __ChainMeta {
    function __id() public pure override returns (string memory) {
        return "sonic";
    }

    function __tokens() public pure override returns (TokenMeta memory t) {
        t.gov = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // wS
        t.wgas = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // wS
        t.usdt = 0x6047828dc181963ba44974801FF68e538dA5eaF9;
        t.usdc = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894;
        t.weth = 0x50c42dEAcD8Fc9773493ED674b675bE577f2634b;
        t.wbtc = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
        t.bnb = address(0);
    }

    function __link() public pure override returns (ChainlinkMeta memory l) {
        l.gov = 0xc76dFb89fF298145b417d221B2c747d84952e01d; // S/USD
        l.gas = 0xc76dFb89fF298145b417d221B2c747d84952e01d; // S/USD
        l.usdt = 0x76F4C040A792aFB7F6dBadC7e30ca3EEa140D216; // USDT/USD
        l.usdc = 0x55bCa887199d5520B3Ce285D41e6dC10C08716C9; // USDC/USD
        l.eth = 0x824364077993847f71293B24ccA8567c00c2de11; // ETH/USD
        l.btc = 0x8Bcd59Cb7eEEea8e2Da3080C891609483dae53EF; // BTC/USD
        l.bnb = address(0);
    }

    function __pyth() public pure override returns (PythMeta memory p) {
        p = super.__pyth();
        p.provider = 0x2880aB155794e7179c9eE2e38200202908C17B43;
    }

    function __aave() public pure override returns (AaveMeta memory a) {
        a.v3PoolProvider = 0x5C2e738F6E27bCE0F7558051Bf90605dD6176900;
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
        return (t.weth, t.wbtc);
    }

    function __testVolatilePools() public pure override returns (address[] memory v3, bytes32[] memory v4) {
        return (new address[](0), new bytes32[](0));
    }

    address internal constant SUSHIV3_WS_USDCE_POOL = 0x48505B3047d5C2af657037034369700F4D036822;
}
