// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {CoreAddresses} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibOracle as O} from "@libraries/LibOracle.sol";
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
 * @title Oracle Test - Tests for Oracle
 * @copyright 2025
 * @notice Unit/integration tests for Oracle functionality
 * @dev Test contract
 * @author BTR Team
 */

contract OracleTest is BaseDiamondTest, BnbChainMeta {
    using C for *;

    OracleFacet internal oracleFacet;
    ChainlinkProvider internal link;
    PythProvider internal pyth;
    TokenMeta internal t;
    CoreAddresses internal tokens;

    uint256 internal constant VALIDITY = 1 days;
    uint256 internal constant PRICE_DEVIATION_THRESHOLD_BPS = 100; // 1%
    uint32 internal constant DEFAULT_TWAP_LOOKBACK = 300; // 5 minutes
    uint256 internal constant DEFAULT_MAX_DEVIATION = 1000; // 10%

    function setUp() public override {
        t = __tokens(); // chain specific tokens
        tokens = CoreAddresses({usdc: t.usdc, weth: t.weth, wbtc: t.wbtc});
        vm.createSelectFork(__id()); // single fork testing: BNB Chain
        super.setUp(); // deploy diamond + facets

        oracleFacet = OracleFacet(diamond); // use oracle facet
        link = new ChainlinkProvider(address(diamond)); // deploy chainlink provider with diamond as admin
        pyth = new PythProvider(address(diamond)); // deploy pyth provider with diamond as admin

        vm.startPrank(admin);
        oracleFacet.initializeOracle(tokens);
        oracleFacet.setProvider(address(link), abi.encode(__testLinkProviderParams())); // initialize chainlink feeds
        oracleFacet.setProvider(address(pyth), abi.encode(__testPythProviderParams())); // initialize pyth feeds
        vm.stopPrank();
    }

    function _assertApproxEq1Pct(uint256 a, uint256 b, string memory message) internal {
        assertApproxEqRel(a, b, 1e16, message); // 1% tolerance
    }

    // --- ORACLE CONFIGURATION TESTS ---

    function testOracleInitialization() public {
        assertEq(oracleFacet.defaultTwapLookback(), 0, "Default TWAP lookback should be 0 initially");
        assertEq(oracleFacet.defaultMaxDeviation(), 0, "Default max deviation should be 0 initially");
    }

    function testSetDefaultTwapLookback() public {
        vm.startPrank(manager);
        oracleFacet.setDefaultTwapLookback(DEFAULT_TWAP_LOOKBACK);
        vm.stopPrank();

        assertEq(oracleFacet.defaultTwapLookback(), DEFAULT_TWAP_LOOKBACK, "Default TWAP lookback should be set");
        assertEq(oracleFacet.twapLookback(bytes32(0)), DEFAULT_TWAP_LOOKBACK, "Feed-specific TWAP should use default");
    }

    function testSetDefaultMaxDeviation() public {
        vm.startPrank(manager);
        oracleFacet.setDefaultMaxDeviation(DEFAULT_MAX_DEVIATION);
        vm.stopPrank();

        assertEq(oracleFacet.defaultMaxDeviation(), DEFAULT_MAX_DEVIATION, "Default max deviation should be set");
        assertEq(
            oracleFacet.maxDeviation(bytes32(0)), DEFAULT_MAX_DEVIATION, "Feed-specific deviation should use default"
        );
    }

    function testSetFeedSpecificTwapLookback() public {
        bytes32 feedId = t.weth.toBytes32();
        uint32 customLookback = 600; // 10 minutes

        vm.startPrank(manager);
        oracleFacet.setTwapLookback(feedId, customLookback);
        vm.stopPrank();

        assertEq(oracleFacet.twapLookback(feedId), customLookback, "Feed-specific TWAP should be set");
    }

    function testSetFeedSpecificMaxDeviation() public {
        bytes32 feedId = t.weth.toBytes32();
        uint256 customDeviation = 500; // 5%

        vm.startPrank(manager);
        oracleFacet.setMaxDeviation(feedId, customDeviation);
        vm.stopPrank();

        assertEq(oracleFacet.maxDeviation(feedId), customDeviation, "Feed-specific deviation should be set");
    }

    function testSetFeed() public {
        bytes32 feedId = t.usdc.toBytes32();
        bytes32 providerId = "test-provider-id";
        uint256 ttl = 3600; // 1 hour

        vm.startPrank(manager);
        oracleFacet.setFeed(feedId, address(link), providerId, ttl);
        vm.stopPrank();

        assertTrue(oracleFacet.hasFeed(feedId), "Feed should exist");
        assertEq(oracleFacet.provider(feedId), address(link), "Provider should be set correctly");
    }

    function testRemoveFeed() public {
        bytes32 feedId = t.usdc.toBytes32();
        bytes32 providerId = "test-provider-id";
        uint256 ttl = 3600;

        vm.startPrank(manager);
        oracleFacet.setFeed(feedId, address(link), providerId, ttl);
        assertTrue(oracleFacet.hasFeed(feedId), "Feed should exist before removal");

        oracleFacet.removeFeed(feedId);
        assertFalse(oracleFacet.hasFeed(feedId), "Feed should not exist after removal");
        vm.stopPrank();
    }

    function testReplaceProvider() public {
        vm.startPrank(manager);
        // First set some feeds with the old provider
        oracleFacet.setFeed(t.weth.toBytes32(), address(link), "weth-feed", 3600);
        oracleFacet.setFeed(t.wbtc.toBytes32(), address(link), "wbtc-feed", 3600);

        // Replace with new provider
        oracleFacet.setProvider(address(pyth), address(link), abi.encode(__testPythProviderParams()));

        // Check that feeds now use the new provider
        assertEq(oracleFacet.provider(t.weth.toBytes32()), address(pyth), "WETH feed should use new provider");
        assertEq(oracleFacet.provider(t.wbtc.toBytes32()), address(pyth), "WBTC feed should use new provider");
        vm.stopPrank();
    }

    function testRemoveProvider() public {
        ChainlinkProvider newProvider = new ChainlinkProvider(address(diamond));

        vm.startPrank(manager);
        oracleFacet.setProvider(address(newProvider), abi.encode(__testLinkProviderParams()));
        oracleFacet.removeProvider(address(newProvider));
        vm.stopPrank();
    }

    // --- PRICE PROVIDER TESTS ---

    function testPriceProviderConsistency() public {
        // Register providers for specific feeds
        vm.startPrank(manager);
        oracleFacet.setFeed(t.usdc.toBytes32(), address(link), "usdc-chainlink", 3600);
        oracleFacet.setFeed(t.weth.toBytes32(), address(pyth), "weth-pyth", 3600);
        vm.stopPrank();

        // Test toUsd for single unit
        uint256 linkUsdcPrice = oracleFacet.toUsd(t.usdc, 1e6);
        uint256 pythWethPrice = oracleFacet.toUsd(t.weth, 1e18);

        assertTrue(linkUsdcPrice > 0, "USDC price should be positive");
        assertTrue(pythWethPrice > 0, "WETH price should be positive");
    }

    function testPriceConversions() public {
        vm.startPrank(manager);
        oracleFacet.setFeed(t.usdc.toBytes32(), address(link), "usdc-chainlink", 3600);
        oracleFacet.setFeed(t.weth.toBytes32(), address(link), "weth-chainlink", 3600);
        vm.stopPrank();

        // Test toUsd and fromUsd consistency
        uint256 amount = 1000e6; // 1000 USDC
        uint256 usdValue = oracleFacet.toUsd(t.usdc, amount);
        uint256 backToUsdc = oracleFacet.fromUsd(t.usdc, usdValue);

        assertApproxEqAbs(backToUsdc, amount, 1e3, "Round-trip conversion should be consistent");

        // Test exchange rate
        uint256 exchangeRate = oracleFacet.exchangeRate(t.weth, t.usdc);
        uint256 convertedAmount = oracleFacet.convert(t.weth, t.usdc, 1e18);

        assertApproxEqRel(exchangeRate, convertedAmount, 1e14, "Exchange rate should match convert function");
    }

    function testCrossAssetConversions() public {
        vm.startPrank(manager);
        oracleFacet.setFeed(t.weth.toBytes32(), address(link), "weth-chainlink", 3600);
        oracleFacet.setFeed(t.wbtc.toBytes32(), address(link), "wbtc-chainlink", 3600);
        vm.stopPrank();

        // Test BTC conversions
        uint256 ethAmount = 1e18;
        uint256 btcAmount = oracleFacet.toBtc(t.weth, ethAmount);
        uint256 backToEth = oracleFacet.fromBtc(t.weth, btcAmount);

        assertApproxEqRel(backToEth, ethAmount, 1e15, "BTC round-trip should be consistent");

        // Test ETH conversions
        uint256 btcOriginal = 1e8; // 1 BTC
        uint256 ethConverted = oracleFacet.toEth(t.wbtc, btcOriginal);
        uint256 backToBtc = oracleFacet.fromEth(t.wbtc, ethConverted);

        assertApproxEqRel(backToBtc, btcOriginal, 1e15, "ETH round-trip should be consistent");
    }

    function testBasisPointConversions() public {
        vm.startPrank(manager);
        oracleFacet.setFeed(t.usdc.toBytes32(), address(link), "usdc-chainlink", 3600);
        vm.stopPrank();

        uint256 usdBp = oracleFacet.toUsdBp(t.usdc);
        uint256 fromUsdBp = oracleFacet.fromUsdBp(t.usdc);

        assertTrue(usdBp > 0, "USD BP should be positive");
        assertTrue(fromUsdBp > 0, "From USD BP should be positive");

        // Test that BP and regular conversions are consistent
        uint256 regularUsd = oracleFacet.toUsd(t.usdc, 1e6);
        uint256 bpUsd = (usdBp * 1e6) / 1e4; // Convert BP to regular

        assertApproxEqRel(regularUsd, bpUsd, 1e12, "BP and regular conversions should be consistent");
    }

    // --- ACCESS CONTROL TESTS ---

    function testOnlyManagerCanSetFeed() public {
        vm.expectRevert();
        vm.prank(user);
        oracleFacet.setFeed(t.usdc.toBytes32(), address(link), "test", 3600);
    }

    function testOnlyManagerCanRemoveFeed() public {
        vm.expectRevert();
        vm.prank(user);
        oracleFacet.removeFeed(t.usdc.toBytes32());
    }

    function testOnlyManagerCanSetProvider() public {
        vm.expectRevert();
        vm.prank(user);
        oracleFacet.setProvider(address(link), "");
    }

    function testOnlyManagerCanSetTwapLookback() public {
        vm.expectRevert();
        vm.prank(user);
        oracleFacet.setDefaultTwapLookback(300);
    }

    // --- ERROR HANDLING TESTS ---

    function testSetFeedWithZeroFeedId() public {
        vm.startPrank(manager);
        vm.expectRevert(Errors.ZeroValue.selector);
        oracleFacet.setFeed(bytes32(0), address(link), "test", 3600);
        vm.stopPrank();
    }

    function testSetFeedWithZeroProvider() public {
        vm.startPrank(manager);
        vm.expectRevert(Errors.ZeroValue.selector);
        oracleFacet.setFeed(t.usdc.toBytes32(), address(0), "test", 3600);
        vm.stopPrank();
    }

    function testRemoveFeedWithZeroFeedId() public {
        vm.startPrank(manager);
        vm.expectRevert(Errors.ZeroValue.selector);
        oracleFacet.removeFeed(bytes32(0));
        vm.stopPrank();
    }
}
