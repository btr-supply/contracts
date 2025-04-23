// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title QuickSwap V3 Adapter - QuickSwap V3 integration
 * @copyright 2025
 * @notice Implements QuickSwap V3 specific DEX operations
 * @dev 
 * @author BTR Team
 */

import {IQuickV3Pool} from "@interfaces/dexs/IQuickV3Pool.sol";
import {AlgebraV3AdapterFacet} from "@facets/adapters/dexs/AlgebraV3AdapterFacet.sol";

contract QuickV3AdapterFacet is AlgebraV3AdapterFacet {
    function _getPoolSqrtPriceAndTick(address pool) internal view override returns (uint160 sqrtPriceX96, int24 tick) {
        (sqrtPriceX96, tick,,,,,) = IQuickV3Pool(pool).globalState();
    }
}
