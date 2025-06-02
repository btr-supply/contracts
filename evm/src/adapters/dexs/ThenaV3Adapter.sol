// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {IThenaV3Pool} from "@interfaces/dexs/IThenaV3Pool.sol";
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
 * @title Thena V3 Adapter - Thena V3 integration
 * @copyright 2025
 * @notice Implements Thena V3 specific DEX operations
 * @dev Inherits from AlgebraV3Adapter
 * @author BTR Team
 */

contract ThenaV3Adapter is AlgebraV3Adapter {
    constructor(address _diamond) AlgebraV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IThenaV3Pool(_pool).globalState();
    }
}
