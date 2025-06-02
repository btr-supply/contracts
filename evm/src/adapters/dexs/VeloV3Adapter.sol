// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVeloV3Pool} from "@interfaces/dexs/IVeloV3Pool.sol";
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
 * @title Velodrome V3 Adapter - Velodrome V3 integration
 * @copyright 2025
 * @notice Implements Velodrome V3 specific DEX operations
 * @dev Inherits from UniV3Adapter
 * @author BTR Team
 */

contract VeloV3Adapter is UniV3Adapter {
    using SafeERC20 for IERC20;

    constructor(address _diamond) UniV3Adapter(_diamond) {}

    function _poolState(address _pool) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,,,) = IVeloV3Pool(_pool).slot0();
        return (priceX96, tick);
    }
}
