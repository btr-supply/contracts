// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ErrorType, CoreAddresses} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibOracle as O} from "@libraries/LibOracle.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";
import {PriceAwareFacet} from "@facets/abstract/PriceAwareFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Oracle Facet - Oracle management and price feeds
 * @copyright 2025
 * @notice Manages oracle configurations, price feeds, and price validation
 * @dev Manages oracle providers and price feed configurations
- Handles Chainlink, Pyth, and other oracle integrations
- Provides price validation and TWAP functionality

 * @author BTR Team
 */

contract OracleFacet is PermissionedFacet, PriceAwareFacet {
    // --- INITIALIZATION ---
    function initializeOracle(CoreAddresses memory _tokens) external {
        O.initialize(S.ora(), _tokens);
    }

    // --- ORACLE VIEWS ---

    function twapLookback(bytes32 _feed) external view returns (uint32) {
        return O.twapLookback(S.ora(), _feed);
    }

    function defaultTwapLookback() external view returns (uint32) {
        return O.getDefaultTwapLookback(S.ora());
    }

    function maxDeviation(bytes32 _feed) external view returns (uint256) {
        return O.maxDeviation(S.ora(), _feed);
    }

    function defaultMaxDeviation() external view returns (uint256) {
        return O.getDefaultMaxDeviation(S.ora());
    }

    function provider(bytes32 _feed) external view returns (address) {
        return O.provider(S.ora(), _feed);
    }

    function hasFeed(bytes32 _feed) external view returns (bool) {
        return O.hasFeed(S.ora(), _feed);
    }

    // --- ORACLE CONFIGURATION ---

    function setFeed(bytes32 _feed, address _provider, bytes32 _providerId, uint256 _ttl) external onlyManager {
        O.setFeed(S.ora(), _feed, _provider, _providerId, _ttl);
    }

    function removeFeed(bytes32 _feed) external onlyManager {
        O.removeFeed(S.ora(), _feed);
    }

    function setProvider(address _provider, address _replacing, bytes calldata _params) external onlyManager {
        O.setProvider(S.ora(), _provider, _replacing, _params);
    }

    function setProvider(address _provider, bytes calldata _params) external onlyManager {
        O.setProvider(S.ora(), _provider, _params);
    }

    function removeProvider(address _provider) external onlyManager {
        O.removeProvider(S.ora(), _provider);
    }

    function setAlt(address _provider, address _alt) external onlyManager {
        O.setAlt(_provider, _alt);
    }

    function removeAlt(address _provider) external onlyManager {
        O.removeAlt(_provider);
    }

    function setDefaultTwapLookback(uint32 _lookback) external onlyManager {
        O.setDefaultTwapLookback(S.ora(), _lookback);
    }

    function setTwapLookback(bytes32 _feed, uint32 _lookback) external onlyManager {
        O.setTwapLookback(S.ora(), _feed, _lookback);
    }

    function setDefaultMaxDeviation(uint256 _maxDeviationBp) external onlyManager {
        O.setDefaultMaxDeviation(S.ora(), _maxDeviationBp);
    }

    function setMaxDeviation(bytes32 _feed, uint256 _maxDeviationBp) external onlyManager {
        O.setMaxDeviation(S.ora(), _feed, _maxDeviationBp);
    }
}
