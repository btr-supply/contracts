// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {V3TickAdapter} from "@dexs/V3TickAdapter.sol";

/*
 * @title Sailor V3 Adapter - Sailor V3 integration
 * @copyright 2025
 * @notice Implements Sailor V3 specific DEX operations (Uniswap V3 based)
 * @dev Inherits from V3TickAdapter
 * @author BTR Team
 */

contract SailorV3Adapter is V3TickAdapter {
    constructor(address _diamond) V3TickAdapter(_diamond) {}
}
