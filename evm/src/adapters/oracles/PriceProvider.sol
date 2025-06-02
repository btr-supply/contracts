// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType} from "@/BTRTypes.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {IOracleAdapter} from "@interfaces/IOracleAdapter.sol";
import {OracleAdapter} from "./OracleAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Price Provider Base - Abstract base for market data providers
 * @copyright 2025
 * @author BTR Team
 */

abstract contract PriceProvider is OracleAdapter, IPriceProvider {
    using M for uint256;
    using C for bytes32;

    // --- CONSTANTS ---

    uint256 public constant USD_DECIMALS = 18;
    uint256 public constant WEI_PER_USD = 10 ** USD_DECIMALS;

    // --- INTERNAL STORAGE ---

    mapping(address => uint8) internal decimalsByAsset;

    // --- CONSTRUCTOR ---

    constructor(address _diamond) OracleAdapter(_diamond) {}

    // --- VIEWS ---

    function hasFeed(address _asset) public view returns (bool) {
        return decimalsByAsset[_asset] > 0;
    }

    function hasFeed(bytes32 _feed) public view override(IOracleAdapter, OracleAdapter) returns (bool) {
        return decimalsByAsset[_feed.toAddress()] > 0;
    }

    function _decimals(address _asset) internal view returns (uint8) {
        uint8 cachedDecimals = decimalsByAsset[_asset];
        if (cachedDecimals > 0) {
            return cachedDecimals;
        }
        return IERC20Metadata(_asset).decimals();
    }

    function _toUsdBp(address _asset, bool _invert) internal view virtual returns (uint256);

    function toUsdBp(address _asset) public view override returns (uint256) {
        return _toUsdBp(_asset, false);
    }

    function fromUsdBp(address _asset) public view override returns (uint256) {
        return _toUsdBp(_asset, true);
    }

    function toUsdBp(address _asset, uint256 _amount) public view returns (uint256) {
        return _toUsdBp(_asset, false) * _amount / (10 ** _decimals(_asset));
    }

    function fromUsdBp(address _asset, uint256 _amount) public view returns (uint256) {
        return _toUsdBp(_asset, true) * _amount / WEI_PER_USD;
    }

    function toUsd(address _asset) public view returns (uint256) {
        return _toUsdBp(_asset, false) / M.BPS;
    }

    function toUsd(address _asset, uint256 _amount) public view override returns (uint256) {
        return toUsdBp(_asset, _amount) / M.BPS;
    }

    function fromUsd(address _asset) public view returns (uint256) {
        return _toUsdBp(_asset, true) / M.BPS;
    }

    function fromUsd(address _asset, uint256 _amount) public view override returns (uint256) {
        return fromUsdBp(_asset, _amount) / M.BPS;
    }

    // --- ASSET CONVERSION METHODS ---

    function convert(address _base, address _quote, uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256 quoteAmount)
    {
        if (_quote == _base) return _amount;

        quoteAmount = fromUsd(_quote, toUsd(_base, _amount));
        if (quoteAmount == 0 && alt != address(0)) {
            // Fallback to alt provider
            try IPriceProvider(alt).convert(_base, _quote, _amount) returns (uint256 altAmount) {
                quoteAmount = altAmount;
            } catch {} // Silently fail and continue with zero amount
        }
        if (quoteAmount == 0) revert Errors.StalePrice();
    }

    function exchangeRateBp(address _base, address _quote) public view override returns (uint256) {
        return convert(_base, _quote, 10 ** _decimals(_base) * M.BPS);
    }

    function exchangeRate(address _base, address _quote) public view override returns (uint256) {
        return convert(_base, _quote, 10 ** _decimals(_base));
    }
}
