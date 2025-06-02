// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Range, PoolInfo} from "@/BTRTypes.sol";

interface IALMInfo {
    function vaultCount() external view returns (uint32);
    function rangeCount() external view returns (uint32);
    function name(uint32 _vid) external view returns (string memory);
    function symbol(uint32 _vid) external view returns (string memory);
    function decimals(uint32 _vid) external view returns (uint8);
    function totalSupply(uint32 _vid) external view returns (uint256);
    function maxSupply(uint32 _vid) external view returns (uint256);
    function balanceOf(uint32 _vid, address _account) external view returns (uint256);
    function allowance(uint32 _vid, address _owner, address _spender) external view returns (uint256);
    function isMintRestricted(uint32 _vid) external view returns (bool);
    function isMinterUnrestricted(uint32 _vid, address _account) external view returns (bool);
    function token0(uint32 _vid) external view returns (address);
    function token1(uint32 _vid) external view returns (address);
    function totalBalances(uint32 _vid) external view returns (uint256 balance0, uint256 balance1);
    function lpBalances(uint32 _vid) external view returns (uint256 balance0, uint256 balance1);
    function cash0(uint32 _vid) external view returns (uint256);
    function cash1(uint32 _vid) external view returns (uint256);
    function weights(uint32 _vid) external view returns (uint16[] memory);
    function targetRatio0(uint32 _vid) external view returns (uint256 targetPBp0);
    function targetRatio1(uint32 _vid) external view returns (uint256 targetPBp1);
    function ratios0(uint32 _vid) external view returns (uint256[] memory);
    function ratios1(uint32 _vid) external view returns (uint256[] memory);
    function poolInfo(bytes32 _pid) external view returns (PoolInfo memory);
    function range(bytes32 _rid) external view returns (Range memory);
    function vaultRangeIds(uint32 _vid) external view returns (bytes32[] memory);
    function ranges(uint32 _vid) external view returns (Range[] memory r);
    function rangeDexAdapter(bytes32 _rid) external view returns (address);
    function rangeRatio0(bytes32 _rid) external view returns (uint256 ratioPBp0);
    function rangeRatio1(bytes32 _rid) external view returns (uint256 ratioPBp1);
    function lpPrice0(bytes32 _rid) external view returns (uint256);
    function lpPrice1(bytes32 _rid) external view returns (uint256);
    function poolPrice(bytes32 _pid) external view returns (uint256);
    function vwap(uint32 _vid) external view returns (uint256);
}
