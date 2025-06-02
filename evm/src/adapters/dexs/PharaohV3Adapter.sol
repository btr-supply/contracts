// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {IPharaohV3Pool} from "@interfaces/dexs/IPharaohV3Pool.sol";
import {RamsesV3Adapter} from "@dexs/RamsesV3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Pharaoh V3 Adapter - Pharaoh V3 integration
 * @copyright 2025
 * @notice Implements Pharaoh V3 specific DEX operations
 * @dev Inherits from RamsesV3Adapter
 * @author BTR Team
 */

contract PharaohV3Adapter is RamsesV3Adapter {
    constructor(address _diamond) RamsesV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IPharaohV3Pool(_pool).slot0();
    }
}
