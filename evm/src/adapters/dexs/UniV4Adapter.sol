// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {V4TickAdapter} from "@dexs/V4TickAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Uniswap V4 Adapter - Uniswap V4 integration
 * @copyright 2025
 * @notice Implements Uniswap V4 specific DEX operations using PoolManager and PositionManager
 * @dev Inherits from V4TickAdapter, implements V4's unlock pattern and PoolKey structure
 * @author BTR Team
 */

contract UniV4Adapter is V4TickAdapter {
    constructor(address _diamond, address _poolManager, address payable _positionManager, address _stateView)
        V4TickAdapter(_diamond, _poolManager, _positionManager, _stateView)
    {}
}
