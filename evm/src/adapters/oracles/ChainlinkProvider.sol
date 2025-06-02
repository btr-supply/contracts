// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType} from "@/BTRTypes.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IChainlinkAggregatorV3} from "@interfaces/oracles/IChainlink.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {PriceProvider} from "./PriceProvider.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Chainlink Provider - Chainlink oracle integration
 * @copyright 2025
 * @author BTR Team
 */

contract ChainlinkProvider is PriceProvider {
    using M for uint256;
    using C for address;

    // --- STORAGE ---

    mapping(address => IChainlinkAggregatorV3) internal aggByAsset;
    mapping(IChainlinkAggregatorV3 => uint8) private aggDecimals;

    // --- CONSTRUCTOR ---

    constructor(address _diamond) PriceProvider(_diamond) {}

    // --- ORACLE IMPLEMENTATION ---

    function _validateAggregator(IChainlinkAggregatorV3 _aggregator) internal view {
        try _aggregator.latestRoundData() returns (uint80, int256 answer, uint256, uint256, uint80) {
            if (answer <= 0) revert Errors.UnexpectedOutput(); // Non valid AggregatorV3 response
        } catch {
            revert Errors.StaticCallFailed(); // Non respondant AggregatorV3
        }
    }

    function _setFeed(bytes32 _feed, bytes32 _providerId, uint256 _ttl) internal override {
        IChainlinkAggregatorV3 agg = IChainlinkAggregatorV3(address(uint160(uint256(_providerId))));
        address asset = address(uint160(uint256(_feed)));
        if (address(agg) == address(0) || asset == address(0)) revert Errors.ZeroAddress();
        _validateAggregator(agg);
        decimalsByAsset[asset] = IERC20Metadata(asset).decimals();
        aggByAsset[asset] = agg;
        ttlByFeed[_feed] = _ttl;
        aggDecimals[agg] = agg.decimals();
    }

    function _removeFeed(bytes32 _feed) internal override {
        address asset = address(uint160(uint256(_feed)));
        delete aggByAsset[asset];
        delete decimalsByAsset[asset];
        super._removeFeed(_feed);
    }

    function _update(bytes calldata _params) internal override {
        IPriceProvider.ChainlinkParams memory p = abi.decode(_params, (IPriceProvider.ChainlinkParams));
        _setFeeds(p.feeds, p.providerIds, p.ttls);
    }

    // --- PRICE PROVIDER IMPLEMENTATION ---

    function _aggDecimals(IChainlinkAggregatorV3 _agg) internal view returns (uint8 decimals) {
        decimals = aggDecimals[_agg];
        if (decimals == 0 && address(_agg) != address(0)) {
            decimals = _agg.decimals();
        }
    }

    function _toUsdBp(address _asset, bool _invert) internal view override returns (uint256) {
        IChainlinkAggregatorV3 agg = aggByAsset[_asset];
        if (address(agg) == address(0)) {
            // unknown asset
            if (alt == address(0)) {
                return 0; // no fallback
            } else {
                return _invert ? IPriceProvider(alt).fromUsdBp(_asset) : IPriceProvider(alt).toUsdBp(_asset); // fallback (eg. uniswap twap)
            }
        }
        (, int256 basePrice,, uint256 updateTime,) = agg.latestRoundData();
        if (basePrice <= 0 || block.timestamp > (updateTime + ttlByFeed[_asset.toBytes32()])) {
            revert Errors.StalePrice(); // Invalid or stale price
        }
        uint8 aggDecimals_ = _aggDecimals(agg);
        return _invert
            ? ((10 ** (_decimals(_asset) + aggDecimals_) * M.BPS) / uint256(basePrice))
            : (M.BPS * uint256(basePrice) * (10 ** uint256(USD_DECIMALS > aggDecimals_ ? USD_DECIMALS - aggDecimals_ : 0)));
    }
}
