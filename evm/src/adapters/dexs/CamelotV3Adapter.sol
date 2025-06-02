// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {ICamelotV3Pool} from "@interfaces/dexs/ICamelotV3Pool.sol";
import {AlgebraV3Adapter} from "@dexs/AlgebraV3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Camelot V3 Adapter - Camelot V3 integration
 * @copyright 2025
 * @notice Implements Camelot V3 specific DEX operations
 * @dev Inherits from AlgebraV3Adapter
 * @author BTR Team
 */

contract CamelotV3Adapter is AlgebraV3Adapter {
    constructor(address _diamond) AlgebraV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = ICamelotV3Pool(_pool).globalState();
    }
}
