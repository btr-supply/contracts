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
 * @title Thena V3 Adapter - Thena V3 integration
 * @copyright 2025
 * @notice Implements Thena V3 specific DEX operations
 * @dev 
 * @author BTR Team
 */

import {IThenaV3Pool} from "@interfaces/dexs/IThenaV3Pool.sol";
import {AlgebraV3AdapterFacet} from "@facets/adapters/dexs/AlgebraV3AdapterFacet.sol";

contract ThenaV3AdapterFacet is AlgebraV3AdapterFacet {
    function _getPoolSqrtPriceAndTick(address pool)
        internal
        view
        virtual
        override
        returns (uint160 sqrtPriceX96, int24 tick)
    {
        (sqrtPriceX96, tick,,,,,) = IThenaV3Pool(pool).globalState();
    }
}
