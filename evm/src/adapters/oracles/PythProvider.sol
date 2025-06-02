// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType} from "@/BTRTypes.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {IPythAggregator, PythStructs} from "@interfaces/oracles/IPyth.sol";
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
 * @title Pyth Provider - Pyth Network oracle integration
 * @copyright 2025
 * @author BTR Team
 */

contract PythProvider is PriceProvider {
    using M for uint256;
    using C for address;

    // --- STORAGE ---

    IPythAggregator internal pyth;
    mapping(address => bytes32) internal feedIdByAsset;

    // --- CONSTRUCTOR ---

    constructor(address _diamond) PriceProvider(_diamond) {}

    // --- ORACLE IMPLEMENTATION ---

    function _validateAggregator(IPythAggregator _pyth) internal view {
        try _pyth.getValidTimePeriod() returns (uint256) {
            // success
        } catch {
            revert Errors.StaticCallFailed();
        }
    }

    function _setFeed(bytes32 _feed, bytes32 _providerId, uint256 _ttl) internal override {
        address asset = address(uint160(uint256(_feed)));
        if (address(pyth) == address(0)) {
            revert Errors.NotInitialized();
        }
        if (!pyth.priceFeedExists(_providerId)) {
            revert Errors.NotFound(ErrorType.PROTOCOL);
        }
        feedIdByAsset[asset] = _providerId;
        ttlByFeed[_feed] = _ttl;
        decimalsByAsset[asset] = IERC20Metadata(asset).decimals();
    }

    function _removeFeed(bytes32 _feed) internal override {
        address asset = address(uint160(uint256(_feed)));
        delete feedIdByAsset[asset];
        delete decimalsByAsset[asset];
        super._removeFeed(_feed);
    }

    function _update(bytes calldata _params) internal override {
        IPriceProvider.PythParams memory params = abi.decode(_params, (IPriceProvider.PythParams));
        if (params.pyth == address(0)) {
            revert Errors.ZeroAddress();
        }
        pyth = IPythAggregator(params.pyth);
        _validateAggregator(pyth);
        if (params.feeds.length > 0) {
            _setFeeds(params.feeds, params.providerIds, params.ttls);
        }
    }

    // --- PRICE PROVIDER IMPLEMENTATION ---

    function _toUsdBp(address _asset, bool _invert) internal view override returns (uint256) {
        bytes32 feedId = feedIdByAsset[_asset];
        if (feedId == bytes32(0)) {
            if (alt == address(0)) {
                revert Errors.NotFound(ErrorType.PROTOCOL);
            } else {
                return _invert ? IPriceProvider(alt).fromUsdBp(_asset) : IPriceProvider(alt).toUsdBp(_asset); // fallback (eg. uniswap twap)
            }
        }

        PythStructs.Price memory price = pyth.getPriceUnsafe(feedId); // Made safe below

        if (
            price.price < 0 || price.expo > 12 || price.expo < -12
                || block.timestamp > (price.publishTime + ttlByFeed[_asset.toBytes32()])
        ) {
            revert Errors.StalePrice(); // Invalid or stale price
        }

        uint256 price256 = uint256(uint64(price.price));

        if (_invert) {
            int256 decimalOffset = int256(uint256(_decimals(_asset))) - price.expo;
            return decimalOffset >= 0
                ? (10 ** uint256(decimalOffset) * M.BPS) / price256
                : (M.BPS) / (price256 * 10 ** uint256(-decimalOffset));
        } else {
            return M.BPS * price256 * 10 ** uint256(price.expo + int256(USD_DECIMALS));
        }
    }
}
