// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {ISwapXV4Pool} from "@interfaces/dexs/ISwapXV4Pool.sol";
import {AlgebraV4Adapter} from "@dexs/AlgebraV4Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title SwapX V4 Adapter - SwapX V4 integration
 * @copyright 2025
 * @notice Implements SwapX V4 specific DEX operations
 * @dev Inherits from AlgebraV4Adapter
 * @author BTR Team
 */

contract SwapXV4Adapter is AlgebraV4Adapter {
    constructor(address _diamond) AlgebraV4Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,) = ISwapXV4Pool(_pool).globalState();
    }
}
