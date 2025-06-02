// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {IShadowV3Pool} from "@interfaces/dexs/IShadowV3Pool.sol";
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
 * @title Shadow V3 Adapter - Shadow V3 integration
 * @copyright 2025
 * @notice Implements Shadow V3 specific DEX operations
 * @dev Inherits from RamsesV3Adapter
 * @author BTR Team
 */

contract ShadowV3Adapter is RamsesV3Adapter {
    constructor(address _diamond) RamsesV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = IShadowV3Pool(_pool).slot0();
    }
}
