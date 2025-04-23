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
 * @title SwapX Adapter - SwapX integration
 * @copyright 2025
 * @notice Implements SwapX specific DEX operations
 * @dev 
 * @author BTR Team
 */

import {ISwapXV4Pool} from "@interfaces/dexs/ISwapXV4Pool.sol";
import {AlgebraV4AdapterFacet} from "@facets/adapters/dexs/AlgebraV4AdapterFacet.sol";

contract SwapXAdapterFacet is AlgebraV4AdapterFacet {
    function _getPoolSqrtPriceAndTick(address pool)
        internal
        view
        virtual
        override
        returns (uint160 sqrtPriceX96, int24 tick)
    {
        (sqrtPriceX96, tick,,,,) = ISwapXV4Pool(pool).globalState();
    }
}
