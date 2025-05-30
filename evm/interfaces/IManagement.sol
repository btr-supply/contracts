// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AccountStatus as AS} from "@/BTRTypes.sol";

interface IManagement {
    function initializeManagement() external;
    function pause() external;
    function unpause() external;
    function setVersion(uint8 _version) external;
    function setAccountStatus(address _account, AS _status) external;
    function setAccountStatusBatch(address[] calldata _accounts, AS _status) external;
    function addToWhitelist(address _account) external;
    function removeFromList(address _account) external;
    function addToBlacklist(address _account) external;
    function addToListBatch(address[] calldata _accounts, AS _status) external;
    function removeFromListBatch(address[] calldata _accounts) external;
    function setSwapCallerRestriction(bool _value) external;
    function setSwapRouterRestriction(bool _value) external;
    function setSwapInputRestriction(bool _value) external;
    function setSwapOutputRestriction(bool _value) external;
    function setBridgeInputRestriction(bool _value) external;
    function setBridgeOutputRestriction(bool _value) external;
    function setBridgeRouterRestriction(bool _value) external;
    function setApproveMax(bool _value) external;
    function setAutoRevoke(bool _value) external;
}
