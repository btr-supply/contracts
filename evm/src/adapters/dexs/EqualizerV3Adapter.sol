// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

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
 * @title Equalizer V3 Adapter - Equalizer V3 integration
 * @copyright 2025
 * @notice Implements Equalizer V3 specific DEX operations
 * @dev Inherits from UniV3Adapter
 * @author BTR Team
 */

contract EqualizerV3Adapter is UniV3Adapter {
    constructor(address _diamond) UniV3Adapter(_diamond) {}
}
