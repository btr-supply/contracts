// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {LibCast as C} from "@libraries/LibCast.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import "forge-std/Test.sol";
import {BnbChainMeta} from "@utils/meta/BNBChain.sol";
import {ChainlinkProvider} from "@oracles/ChainlinkProvider.sol";
import {OracleFacet} from "@facets/OracleFacet.sol";
import {PythProvider} from "@oracles/PythProvider.sol";
import {TokenMeta, ChainlinkMeta, PythMeta} from "@utils/meta/__ChainMeta.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title PriceProvider Test - Tests for PriceProvider
 * @copyright 2025
 * @notice Unit/integration tests for PriceProvider functionality
 * @dev Test contract
 * @author BTR Team
 */

contract PriceProviderTest is BaseDiamondTest, BnbChainMeta {
    using C for *;

    OracleFacet internal oracleFacet;
    ChainlinkProvider internal link;
    PythProvider internal pyth;
    TokenMeta internal t;
    uint256 internal constant VALIDITY = 1 days;
    uint256 internal constant PRICE_DEVIATION_THRESHOLD_BPS = 100; // 1%

    function setUp() public override {
        t = __tokens(); // chain specific tokens
        vm.createSelectFork(__id()); // single fork testing: BNB Chain
        super.setUp(); // deploy diamond + facets

        oracleFacet = OracleFacet(diamond); // use oracle facet
        link = new ChainlinkProvider(address(diamond)); // deploy chainlink provider with diamond as admin
        pyth = new PythProvider(address(diamond)); // deploy pyth provider with diamond as admin

        vm.startPrank(admin);
        oracleFacet.setProvider(address(link), abi.encode(__testLinkProviderParams())); // initialize chainlink feeds
        oracleFacet.setProvider(address(pyth), abi.encode(__testPythProviderParams())); // initialize pyth feeds
        vm.stopPrank();
    }

    function _assertApproxEq1Pct(uint256 a, uint256 b, string memory message) internal {
        assertApproxEqRel(a, b, 1e16, message); // 1% tolerance
    }

    function testProviderst() public {
        (uint256 linkPrice, uint256 pythPrice) = (0, 0);
        // Test toUsd for single unit
        _assertApproxEq1Pct(link.toUsd(t.usdc), pyth.toUsd(t.usdc), "USDC/USD");
        _assertApproxEq1Pct(link.toUsd(t.weth), pyth.toUsd(t.weth), "WETH/USD");
        _assertApproxEq1Pct(link.toUsd(t.wbtc), pyth.toUsd(t.wbtc), "WBTC/USD");
        // Test toUsd for multiple units
        _assertApproxEq1Pct(link.toUsd(t.usdc, 1000e6), pyth.toUsd(t.usdc, 1000e6), "1000 USDC to USD");
        _assertApproxEq1Pct(link.toUsd(t.weth, 100e18), pyth.toUsd(t.weth, 100e18), "100 WETH to USD");
        _assertApproxEq1Pct(link.toUsd(t.wbtc, 10e8), pyth.toUsd(t.wbtc, 10e8), "10 WBTC to USD");
        // Test fromUsd for single unit
        _assertApproxEq1Pct(link.fromUsd(t.usdc), pyth.fromUsd(t.usdc), "USD to USDC");
        _assertApproxEq1Pct(link.fromUsd(t.weth), pyth.fromUsd(t.weth), "USD to WETH");
        _assertApproxEq1Pct(link.fromUsd(t.wbtc), pyth.fromUsd(t.wbtc), "USD to WBTC");
        // Test fromUsd for multiple units
        _assertApproxEq1Pct(link.fromUsd(t.usdc, 1000e18), pyth.fromUsd(t.usdc, 1000e18), "1000 USD to USDC");
        _assertApproxEq1Pct(link.fromUsd(t.weth, 3800e18), pyth.fromUsd(t.weth, 3800e18), "3800 USD to WETH");
        _assertApproxEq1Pct(link.fromUsd(t.wbtc, 68000e18), pyth.fromUsd(t.wbtc, 68000e18), "68000 USD to WBTC");
        // Test exchangeRate
        _assertApproxEq1Pct(
            link.exchangeRate(t.wbtc, t.weth), pyth.exchangeRate(t.wbtc, t.weth), "WBTC/WETH exchange rate"
        );
        _assertApproxEq1Pct(
            link.exchangeRate(t.weth, t.wbtc), pyth.exchangeRate(t.weth, t.wbtc), "WETH/WBTC exchange rate"
        );
    }

    function testOracleFacetProxy() public {
        vm.startPrank(admin);
        oracleFacet.setProvider(t.wbtc.toBytes32(), address(link)); // register chainlink provider for wbtc
        oracleFacet.setProvider(t.weth.toBytes32(), address(link)); // register chainlink provider for weth
        vm.stopPrank();
        assertEq(oracleFacet.toUsd(t.wbtc, 1e8), link.toUsd(t.wbtc, 1e8), 1e16, "WBTC to USD via Facet vs Direct"); // proxy vs provider
        assertEq(oracleFacet.toUsd(t.weth, 1e18), link.toUsd(t.weth, 1e18), 1e16, "WETH to USD via Facet vs Direct"); // proxy vs provider
    }
}
