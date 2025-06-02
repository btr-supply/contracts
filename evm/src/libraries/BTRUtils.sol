// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {ALMVault, ErrorType, Range, Restrictions, Registry} from "@/BTRTypes.sol";
import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Utilities Library - General utility functions
 * @copyright 2025
 * @notice Contains various helper functions used across the protocol
 * @dev Utility routines (e.g., bytes32↔uint32 conversions, ID helpers)
- Facilitates diamond storage access and event encoding

 * @author BTR Team
 */

library BTRUtils {
    // --- UTILS ---
    function delegate(address _target, bytes4 _selector) internal returns (bytes memory returnData) {
        (bool success, bytes memory _returnData) = _target.delegatecall(abi.encodeWithSelector(_selector));
        if (!success) revert Errors.DelegateCallFailed();
        returnData = _returnData;
    }

    function delegate(address _target, bytes4 _selector, bytes memory _calldata)
        internal
        returns (bytes memory returnData)
    {
        (bool success, bytes memory _returnData) = _target.delegatecall(abi.encodeWithSelector(_selector, _calldata));
        if (!success) revert Errors.DelegateCallFailed();
        returnData = _returnData;
    }

    function delegate(address _target, bytes memory _calldata) internal returns (bytes memory returnData) {
        (bool success, bytes memory _returnData) = _target.delegatecall(_calldata);
        if (!success) revert Errors.DelegateCallFailed();
        returnData = _returnData;
    }

    function vault(uint32 _vid, Registry storage _reg) internal view returns (ALMVault storage v) {
        v = _reg.vaults[_vid];
        if (v.id != _vid) revert Errors.NotFound(ErrorType.VAULT);
    }

    function vault(uint32 _vid) internal view returns (ALMVault storage v) {
        v = vault(_vid, S.reg());
    }

    function range(bytes32 _rid) internal view returns (Range storage r) {
        r = S.reg().ranges[_rid];
        if (r.id == bytes32(0)) revert Errors.NotFound(ErrorType.RANGE);
    }

    function vaultCount() internal view returns (uint32) {
        return S.reg().vaultCount;
    }

    function rangeCount() internal view returns (uint32) {
        return S.reg().rangeCount;
    }

    function rangeId(uint32 _vid, bytes32 _pid, int24 _tickLower, int24 _tickUpper) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _vid, _pid, _tickLower, _tickUpper));
    }

    function rangeId(bytes32 _rid) public view returns (bytes32) {
        Range storage r = range(_rid);
        return rangeId(r.vaultId, r.poolId, r.lowerTick, r.upperTick);
    }

    function positionId(int24 _tickLower, int24 _tickUpper) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this), _tickLower, _tickUpper)));
    }

    function positionId(bytes32 _rid) public view returns (uint256) {
        Range storage r = range(_rid);
        return positionId(r.lowerTick, r.upperTick);
    }

    function checkMatchTokens(address _vaultToken0, address _vaultToken1, address _poolToken0, address _poolToken1)
        internal
        pure
    {
        if (_vaultToken0 != _poolToken0 || _vaultToken1 != _poolToken1) {
            revert Errors.Unauthorized(ErrorType.TOKEN);
        }
    }
}
