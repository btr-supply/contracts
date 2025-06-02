// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {V2BucketAdapter} from "@dexs/V2BucketAdapter.sol";

/*
 * @title Joe V2 Adapter - Joe V2 integration
 * @copyright 2025
 * @notice Implements Joe V2 specific DEX operations
 * @dev Inherits from V2BucketAdapter
 * @author BTR Team
 */

abstract contract JoeV2Adapter is V2BucketAdapter {
    constructor(address _diamond) V2BucketAdapter(_diamond) {}
}
