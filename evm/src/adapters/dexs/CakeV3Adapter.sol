// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {ICakeV3Pool} from "@interfaces/dexs/ICakeV3Pool.sol";
import {UniV3Adapter} from "@dexs/UniV3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title PancakeSwap V3 Adapter - PancakeSwap V3 integration
 * @copyright 2025
 * @notice Implements PancakeSwap V3 specific DEX operations
 * @dev Inherits from UniV3Adapter
 * @author BTR Team
 */

contract CakeV3Adapter is UniV3Adapter {
    constructor(address _diamond) UniV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,,) = ICakeV3Pool(_pool).slot0();
    }
}
