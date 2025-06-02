// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {IOracleAdapter} from "@interfaces/IOracleAdapter.sol";
import {IPriceProvider} from "@interfaces/IPriceProvider.sol";
import {Permissioned} from "@/abstract/Permissioned.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Oracle Adapter Base - Base contract for oracle integrations
 * @copyright 2025
 * @notice Provides common oracle adapter functionality
 * @dev Base for oracle price providers
 * @author BTR Team
 */

abstract contract OracleAdapter is Permissioned, IOracleAdapter {
    // --- INTERNAL STORAGE ---
    mapping(bytes32 => uint256) internal ttlByFeed;
    address public alt; // alternative oracle (fallback)
    // --- CONSTRUCTOR ---

    constructor(address _diamond) Permissioned(_diamond) {}

    // --- ABSTRACT METHODS ---

    function hasFeed(bytes32 _feed) public view virtual override returns (bool);

    // --- PROTECTED METHODS ---

    function _update(bytes calldata _params) internal virtual;

    function update(bytes calldata _params) external override onlyDiamond {
        _update(_params);
    }

    function _setAlt(address _alt) internal virtual {
        alt = _alt;
    }

    function setAlt(address _alt) external override onlyDiamond {
        _setAlt(_alt);
    }

    function _removeAlt() internal virtual {
        alt = address(0);
    }

    function removeAlt() external override onlyDiamond {
        _removeAlt();
    }

    function _setFeed(bytes32 _feed, bytes32 _providerId, uint256 _ttl) internal virtual;

    function setFeed(bytes32 _feed, bytes32 _providerId, uint256 _ttl) external override onlyDiamond {
        _setFeed(_feed, _providerId, _ttl);
    }

    function _removeFeed(bytes32 _feed) internal virtual {
        delete ttlByFeed[_feed];
    }

    function removeFeed(bytes32 _feed) external onlyDiamond {
        _removeFeed(_feed);
    }

    function _setFeeds(bytes32[] memory _feeds, bytes32[] memory _providerIds, uint256[] memory _ttls)
        internal
        virtual
    {
        if (_feeds.length == 0 || _feeds.length != _providerIds.length || _feeds.length != _ttls.length) {
            revert Errors.UnexpectedInput();
        }
        unchecked {
            for (uint256 i = 0; i < _feeds.length; i++) {
                _setFeed(_feeds[i], _providerIds[i], _ttls[i]);
            }
        }
    }

    function setFeeds(bytes32[] calldata _feeds, bytes32[] calldata _providerIds, uint256[] calldata _ttls)
        external
        override
        onlyDiamond
    {
        _setFeeds(_feeds, _providerIds, _ttls);
    }

    function _setTtl(bytes32 _feed, uint256 _ttl) internal virtual {
        ttlByFeed[_feed] = _ttl;
    }

    function setTtl(bytes32 _feed, uint256 _ttl) external onlyDiamond {
        _setTtl(_feed, _ttl);
    }
}
