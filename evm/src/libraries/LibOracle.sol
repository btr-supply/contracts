// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {ErrorType, Oracles, Feed, CoreAddresses} from "@/BTRTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOracleAdapter} from "@interfaces/IOracleAdapter.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Oracle Library - Oracle management and price validation logic
 * @copyright 2025
 * @notice Contains internal functions for oracle management, price feeds, and validation
 * @dev Helper library for OracleFacet and price-aware components
 * @author BTR Team
 */

library LibOracle {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    // --- INITIALIZATION ---

    function initialize(Oracles storage _ora, CoreAddresses memory _tokens) internal {
        _ora.addresses = _tokens;
    }

    // --- ORACLE VIEWS ---

    function _validateProvider(IOracleAdapter _provider) internal view {
        try _provider.hasFeed(bytes32(0)) returns (bool success) {
            if (!success) revert Errors.UnexpectedOutput();
        } catch {
            revert Errors.StaticCallFailed();
        }
    }

    function tokens(Oracles storage _ora) internal view returns (CoreAddresses memory) {
        return _ora.addresses;
    }

    function feed(Oracles storage _ora, bytes32 _feedId) internal view returns (Feed memory) {
        return _ora.feeds[_feedId];
    }

    function twapLookback(Oracles storage _ora, bytes32 _feedId) internal view returns (uint32) {
        Feed memory feedData = _ora.feeds[_feedId];
        return feedData.twapLookback != 0 ? feedData.twapLookback : _ora.defaultTwapLookback;
    }

    function getDefaultTwapLookback(Oracles storage _ora) internal view returns (uint32) {
        return _ora.defaultTwapLookback;
    }

    function maxDeviation(Oracles storage _ora, bytes32 _feedId) internal view returns (uint256) {
        Feed memory feedData = _ora.feeds[_feedId];
        return feedData.maxDeviationBp != 0 ? feedData.maxDeviationBp : _ora.defaultMaxDeviation;
    }

    function getDefaultMaxDeviation(Oracles storage _ora) internal view returns (uint256) {
        return _ora.defaultMaxDeviation;
    }

    function provider(Oracles storage _ora, bytes32 _feedId) internal view returns (address) {
        return _ora.feeds[_feedId].provider;
    }

    function checkProvider(Oracles storage _ora, bytes32 _feedId) internal view returns (address providerAddr) {
        providerAddr = _ora.feeds[_feedId].provider;
        if (providerAddr == address(0)) revert Errors.NotFound(ErrorType.PROTOCOL);
    }

    function hasFeed(Oracles storage _ora, bytes32 _feedId) internal view returns (bool) {
        address providerAddr = _ora.feeds[_feedId].provider;
        return providerAddr != address(0);
    }

    // --- PROTOCOL ORACLE SETTINGS ---

    function setTwapLookback(Oracles storage _ora, bytes32 _feedId, uint32 _lookback) internal {
        if (_feedId == bytes32(0)) {
            _ora.defaultTwapLookback = _lookback;
        } else {
            _ora.feeds[_feedId].twapLookback = uint16(_lookback);
        }
        emit Events.TwapLookbackUpdated(_feedId, _lookback);
    }

    function setDefaultTwapLookback(Oracles storage _ora, uint32 _lookback) internal {
        setTwapLookback(_ora, bytes32(0), _lookback);
    }

    function setMaxDeviation(Oracles storage _ora, bytes32 _feedId, uint256 _maxDeviationBp) internal {
        if (_feedId == bytes32(0)) {
            _ora.defaultMaxDeviation = _maxDeviationBp;
        } else {
            _ora.feeds[_feedId].maxDeviationBp = uint16(_maxDeviationBp);
        }
        emit Events.MaxDeviationUpdated(_feedId, _maxDeviationBp);
    }

    function setDefaultMaxDeviation(Oracles storage _ora, uint256 _maxDeviationBp) internal {
        setMaxDeviation(_ora, bytes32(0), _maxDeviationBp);
    }

    // --- PROVIDER MANAGEMENT ---

    function setFeed(Oracles storage _ora, bytes32 _feedId, address _provider, bytes32 _providerId, uint256 _ttl)
        internal
    {
        if (_provider == address(0)) revert Errors.ZeroAddress();
        if (_feedId == bytes32(0)) revert Errors.ZeroValue();

        // Remove from old provider if exists
        address oldProvider = _ora.feeds[_feedId].provider;
        if (oldProvider != address(0)) {
            _ora.providerFeeds[oldProvider].remove(_feedId); // Remove old provider
        }

        _ora.feeds[_feedId].provider = _provider;
        _ora.providerFeeds[_provider].add(_feedId);
        emit Events.DataFeedUpdated(_feedId, _provider, _providerId, _ttl);
    }

    function removeFeed(Oracles storage _ora, bytes32 _feedId) internal {
        checkProvider(_ora, _feedId); // Ensure feed exists
        address providerAddr = _ora.feeds[_feedId].provider;
        _ora.providerFeeds[providerAddr].remove(_feedId);

        // Clear the feed
        delete _ora.feeds[_feedId];
        emit Events.DataFeedRemoved(_feedId, providerAddr);
    }

    function setProvider(Oracles storage _ora, address _provider, address _replacing, bytes calldata _params)
        internal
    {
        if (_provider == address(0)) revert Errors.ZeroAddress();
        if (_replacing == _provider) revert Errors.AlreadyExists(ErrorType.ADDRESS);

        // Update the provider with parameters
        IOracleAdapter(_provider).update(_params);

        // If replacing, transfer feeds
        if (_replacing != address(0)) {
            EnumerableSet.Bytes32Set storage feeds = _ora.providerFeeds[_replacing];
            uint256 feedCount = feeds.length();

            for (uint256 i = 0; i < feedCount; i++) {
                bytes32 feedId = feeds.at(0); // Always take the first element
                Feed storage feedData = _ora.feeds[feedId];
                feedData.provider = _provider;

                feeds.remove(feedId); // Remove from old provider
                _ora.providerFeeds[_provider].add(feedId); // Add to new provider
            }

            // Clean up old provider - no cleanup method in interface, so skip
            emit Events.DataProviderUpdated(_replacing, _provider);
        }

        emit Events.DataProviderUpdated(address(0), _provider);
    }

    function setProvider(Oracles storage _ora, address _provider, bytes calldata _params) internal {
        setProvider(_ora, _provider, address(0), _params);
    }

    function removeProvider(Oracles storage _ora, address _provider) internal {
        if (_provider == address(0)) revert Errors.ZeroAddress();

        // Ensure no feeds are using this provider
        if (_ora.providerFeeds[_provider].length() != 0) {
            revert Errors.Failed(ErrorType.PROTOCOL);
        }
        delete _ora.providerFeeds[_provider];

        // Clean up provider - no cleanup method in interface, so skip
        emit Events.DataProviderRemoved(_provider);
    }

    function setAlt(address _provider, address _alt) internal {
        if (_alt == address(0)) revert Errors.ZeroAddress();
        if (_provider == _alt) revert Errors.AlreadyInitialized();
        IOracleAdapter(_provider).setAlt(_alt);
    }

    function removeAlt(address _provider) internal {
        IOracleAdapter(_provider).removeAlt();
    }

    // --- PRICE PROVIDER VIEWS ---

    function toUsdBp(Oracles storage _ora, address _asset) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_asset))))).toUsdBp(_asset);
    }

    function fromUsdBp(Oracles storage _ora, address _asset) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_asset))))).fromUsdBp(_asset);
    }

    function toUsd(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_asset))))).toUsd(_asset, _amount);
    }

    function fromUsd(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_asset))))).fromUsd(_asset, _amount);
    }

    function convert(Oracles storage _ora, address _base, address _quote, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_base))))).convert(_base, _quote, _amount);
    }

    function exchangeRate(Oracles storage _ora, address _base, address _quote) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_base))))).exchangeRate(_base, _quote);
    }

    function exchangeRateBp(Oracles storage _ora, address _base, address _quote) internal view returns (uint256) {
        return IPriceProvider(checkProvider(_ora, bytes32(uint256(uint160(_base))))).exchangeRateBp(_base, _quote);
    }

    function toBtc(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return convert(_ora, _asset, tokens(_ora).wbtc, _amount);
    }

    function fromBtc(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return convert(_ora, tokens(_ora).wbtc, _asset, _amount);
    }

    function toEth(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return convert(_ora, _asset, tokens(_ora).weth, _amount);
    }

    function fromEth(Oracles storage _ora, address _asset, uint256 _amount) internal view returns (uint256) {
        return convert(_ora, tokens(_ora).weth, _asset, _amount);
    }
}
