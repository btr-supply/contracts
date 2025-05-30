// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibOracle as O} from "@libraries/LibOracle.sol";
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
 * @title Price Aware Facet - Abstract base for price-aware facets
 * @copyright 2025
 * @notice Provides price validation and oracle integration for facets
 * @dev Used by facets that need price feed validation
 * @author BTR Team
 */

abstract contract PriceAwareFacet {
    function toUsdBp(address _asset) external view returns (uint256) {
        return O.toUsdBp(S.ora(), _asset);
    }

    function fromUsdBp(address _asset) external view returns (uint256) {
        return O.fromUsdBp(S.ora(), _asset);
    }

    function toUsd(address _asset, uint256 _amount) external view returns (uint256) {
        return O.toUsd(S.ora(), _asset, _amount);
    }

    function fromUsd(address _asset, uint256 _amount) external view returns (uint256) {
        return O.fromUsd(S.ora(), _asset, _amount);
    }

    function convert(address _base, address _quote, uint256 _amount) external view returns (uint256) {
        return O.convert(S.ora(), _base, _quote, _amount);
    }

    function exchangeRate(address _base, address _quote) external view returns (uint256) {
        return O.exchangeRate(S.ora(), _base, _quote);
    }

    function exchangeRateBp(address _base, address _quote) external view returns (uint256) {
        return O.exchangeRateBp(S.ora(), _base, _quote);
    }

    function toBtc(address _asset, uint256 _amount) external view returns (uint256) {
        return O.toBtc(S.ora(), _asset, _amount);
    }

    function fromBtc(address _asset, uint256 _amount) external view returns (uint256) {
        return O.fromBtc(S.ora(), _asset, _amount);
    }

    function toEth(address _asset, uint256 _amount) external view returns (uint256) {
        return O.toEth(S.ora(), _asset, _amount);
    }

    function fromEth(address _asset, uint256 _amount) external view returns (uint256) {
        return O.fromEth(S.ora(), _asset, _amount);
    }
}
