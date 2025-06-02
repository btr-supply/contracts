// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {V2BucketAdapter} from "@dexs/V2BucketAdapter.sol";

/*
 * @title Moe V2 Adapter - Merchant Moe V2 integration
 * @copyright 2025
 * @notice Implements Merchant Moe V2 specific DEX operations (Joe V2 based)
 * @dev Inherits from V2BucketAdapter
 * @author BTR Team
 */

abstract contract MoeV2Adapter is V2BucketAdapter {
    constructor(address _diamond) V2BucketAdapter(_diamond) {}
}
