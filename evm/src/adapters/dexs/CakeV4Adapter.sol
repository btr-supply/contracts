// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {V4TickAdapter} from "@dexs/V4TickAdapter.sol";

/*
 * @title PancakeSwap V4 Adapter - PancakeSwap V4 integration
 * @copyright 2025
 * @notice Implements PancakeSwap V4 specific DEX operations (Uniswap V4 based)
 * @dev Inherits from V4TickAdapter
 * @author BTR Team
 */

contract CakeV4Adapter is V4TickAdapter {
    constructor(address _diamond, address _poolManager, address payable _positionManager, address _stateView)
        V4TickAdapter(_diamond, _poolManager, _positionManager, _stateView)
    {}
}
