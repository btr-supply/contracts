// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IALMInfo} from "./IALMInfo.sol";
import {IALMProtected} from "./IALMProtected.sol";
import {IALMUser} from "./IALMUser.sol";
import {IAccessControl} from "./IAccessControl.sol";
import {IDiamond, IDiamondCut, IDiamondLoupe} from "./IDiamond.sol";
import {IInfo} from "./IInfo.sol";
import {IManagement} from "./IManagement.sol";
import {IOracle} from "./IOracle.sol";
import {IRescue} from "./IRescue.sol";
import {IRiskModel} from "./IRiskModel.sol";
import {ISwap} from "./ISwap.sol";
import {ITreasury} from "./ITreasury.sol";

interface IBTRDiamond is
    IDiamond,
    IDiamondCut,
    IDiamondLoupe,
    IAccessControl,
    IALMInfo,
    IALMUser,
    IALMProtected,
    IInfo,
    IManagement,
    IOracle,
    IRescue,
    IRiskModel,
    ISwap,
    ITreasury
{
// All functions are inherited from the parent interfaces
}
