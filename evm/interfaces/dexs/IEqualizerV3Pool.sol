// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";

interface IEqualizerV3Pool is IUniV3Pool {
    function setFeeProtocol(uint8 feeProtocolNew) external;
    function setSwapFee(uint24 feeNew) external;
}
