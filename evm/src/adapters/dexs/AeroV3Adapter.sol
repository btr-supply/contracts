// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {IAeroV3Pool} from "@interfaces/dexs/IAeroV3Pool.sol";
import {VeloV3Adapter} from "@dexs/VeloV3Adapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Aerodrome V3 Adapter - Aerodrome V3 integration
 * @copyright 2025
 * @notice Implements Aerodrome V3 specific DEX operations
 * @dev Inherits from VeloV3Adapter
 * @author BTR Team
 */

contract AeroV3Adapter is VeloV3Adapter {
    constructor(address _diamond) VeloV3Adapter(_diamond) {}
}
