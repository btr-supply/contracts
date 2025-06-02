// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {IQuickV3Pool} from "@interfaces/dexs/IQuickV3Pool.sol";
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
 * @title QuickSwap V3 Adapter - QuickSwap V3 integration
 * @copyright 2025
 * @notice Implements QuickSwap V3 specific DEX operations
 * @dev Inherits from AlgebraV3Adapter
 * @author BTR Team
 */

contract QuickV3Adapter is AlgebraV3Adapter {
    constructor(address _diamond) AlgebraV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IQuickV3Pool(_pool).globalState();
    }
}
