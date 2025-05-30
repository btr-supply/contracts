// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    AccountStatus as AS,
    AddressType,
    ErrorType,
    Fees,
    CoreStorage,
    ALMVault,
    Oracles,
    Range,
    Registry,
    Restrictions
} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibBitMask} from "@libraries/LibBitMask.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibPausable as P} from "@libraries/LibPausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Management Library - Protocol parameter management logic
 * @copyright 2025
 * @notice Contains internal functions for setting and getting protocol parameters
 * @dev Helper library for ManagementFacet
 * @author BTR Team
 */

library LibManagement {
    using U for uint32;
    using LibBitMask for uint256;

    // --- CONSTANTS ---

    uint16 internal constant MIN_FEE_BPS = 0;
    uint16 internal constant MAX_FEE_BPS = 5000; // 50%
    uint16 internal constant MAX_FLASH_FEE_BPS = 5000; // 50%
    uint16 internal constant MAX_PERFORMANCE_FEE_BPS = 5000; // 50%
    uint16 internal constant MAX_ENTRY_FEE_BPS = 5000; // 50%
    uint16 internal constant MAX_EXIT_FEE_BPS = 5000; // 50%
    uint16 internal constant MAX_MGMT_FEE_BPS = 5000; // 50%
    uint32 internal constant MIN_TWAP_INTERVAL = 300; // 5 min
    uint32 internal constant MAX_TWAP_INTERVAL = 3600 * 24 * 7; // 7 days
    uint256 internal constant MAX_PRICE_DEVIATION = M.BPS / 3; // 33.33%
    uint256 internal constant MIN_PRICE_DEVIATION = 2; // 0.02%

    // Restriction bit positions
    uint8 internal constant RESTRICT_SWAP_CALLER_BIT = 0;
    uint8 internal constant RESTRICT_SWAP_ROUTER_BIT = 1;
    uint8 internal constant RESTRICT_SWAP_INPUT_BIT = 2;
    uint8 internal constant RESTRICT_SWAP_OUTPUT_BIT = 3;
    uint8 internal constant RESTRICT_BRIDGE_INPUT_BIT = 4;
    uint8 internal constant RESTRICT_BRIDGE_OUTPUT_BIT = 5;
    uint8 internal constant RESTRICT_BRIDGE_ROUTER_BIT = 6;
    uint8 internal constant APPROVE_MAX_BIT = 7;
    uint8 internal constant AUTO_REVOKE_BIT = 8;

    // --- INITIALIZATION ---

    function initialize(
        Restrictions storage _rs,
        bool _restrictSwapCaller,
        bool _restrictSwapRouter,
        bool _restrictSwapInput,
        bool _restrictSwapOutput,
        bool _approveMax,
        bool _autoRevoke
    ) internal {
        uint256 rsMask = 0;
        if (_restrictSwapCaller) rsMask = rsMask.setBit(RESTRICT_SWAP_CALLER_BIT);
        if (_restrictSwapRouter) rsMask = rsMask.setBit(RESTRICT_SWAP_ROUTER_BIT);
        if (_restrictSwapInput) rsMask = rsMask.setBit(RESTRICT_SWAP_INPUT_BIT);
        if (_restrictSwapOutput) rsMask = rsMask.setBit(RESTRICT_SWAP_OUTPUT_BIT);
        if (_approveMax) rsMask = rsMask.setBit(APPROVE_MAX_BIT);
        if (_autoRevoke) rsMask = rsMask.setBit(AUTO_REVOKE_BIT);
        _rs.restrictionMask = rsMask;
    }

    // --- MANAGEMENT ---

    function version(CoreStorage storage _cs) internal view returns (uint8) {
        return _cs.version;
    }

    function setVersion(CoreStorage storage _cs, uint8 newVersion) internal {
        _cs.version = newVersion;
        emit Events.VersionUpdated(newVersion);
    }

    // --- ORACLES ---

    function validatePriceProtection(uint32 _lookback, uint256 _maxDeviation) internal pure {
        if (_lookback < MIN_TWAP_INTERVAL) revert Errors.Exceeds(MIN_TWAP_INTERVAL, _lookback);
        if (_lookback > MAX_TWAP_INTERVAL) revert Errors.Exceeds(_lookback, MAX_TWAP_INTERVAL);
        if (_maxDeviation < MIN_PRICE_DEVIATION) {
            revert Errors.Exceeds(MIN_PRICE_DEVIATION, _maxDeviation);
        }
        if (_maxDeviation > MAX_PRICE_DEVIATION) {
            revert Errors.Exceeds(_maxDeviation, MAX_PRICE_DEVIATION);
        }
    }

    function setDefaultPriceProtection(Oracles storage _ora, uint32 _lookback, uint256 _maxDeviation) internal {
        validatePriceProtection(_lookback, _maxDeviation);
        _ora.defaultTwapLookback = _lookback;
        _ora.defaultMaxDeviation = _maxDeviation;
        _ora.defaultTwapLookback = _lookback;
        emit Events.DefaultPriceProtectionUpdated(_lookback, _maxDeviation);
    }

    function setVaultPriceProtection(ALMVault storage _vault, uint32 _lookback, uint256 _maxDeviation) internal {
        validatePriceProtection(_lookback, _maxDeviation);
        _vault.lookback = _lookback;
        _vault.maxDeviation = _maxDeviation;
        emit Events.VaultPriceProtectionUpdated(_vault.id, _lookback, _maxDeviation);
    }

    // --- RESTRICTION MAP (SWAPS/BRIDGES/ORACLES) ---

    function mask(Restrictions storage _rs) internal view returns (uint256) {
        return _rs.restrictionMask;
    }

    function setRestriction(Restrictions storage _rs, uint8 _bit, bool _value) internal {
        uint256 rsMask = _rs.restrictionMask;
        _rs.restrictionMask = _value ? rsMask.setBit(_bit) : rsMask.resetBit(_bit);
        emit Events.RestrictionUpdated(_bit, _value);
    }

    function setSwapCallerRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_SWAP_CALLER_BIT, _value);
    }

    function setSwapRouterRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_SWAP_ROUTER_BIT, _value);
    }

    function setSwapInputRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_SWAP_INPUT_BIT, _value);
    }

    function setSwapOutputRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_SWAP_OUTPUT_BIT, _value);
    }

    function setBridgeInputRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_BRIDGE_INPUT_BIT, _value);
    }

    function setBridgeOutputRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_BRIDGE_OUTPUT_BIT, _value);
    }

    function setBridgeRouterRestriction(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, RESTRICT_BRIDGE_ROUTER_BIT, _value);
    }

    function setApproveMax(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, APPROVE_MAX_BIT, _value);
    }

    function setAutoRevoke(Restrictions storage _rs, bool _value) internal {
        setRestriction(_rs, AUTO_REVOKE_BIT, _value);
    }

    // --- RESTRICTION CHECKS ---

    function isRestricted(Restrictions storage _rs, uint8 _bit, address _address) internal view returns (bool) {
        return _rs.restrictionMask.getBit(_bit) && !AC.isWhitelisted(_rs, _address);
    }

    function isSwapCallerRestricted(Restrictions storage _rs, address _caller) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_SWAP_CALLER_BIT, _caller);
    }

    function isSwapRouterRestricted(Restrictions storage _rs, address _router) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_SWAP_ROUTER_BIT, _router);
    }

    function isSwapInputRestricted(Restrictions storage _rs, address _input) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_SWAP_INPUT_BIT, _input);
    }

    function isSwapOutputRestricted(Restrictions storage _rs, address _output) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_SWAP_OUTPUT_BIT, _output);
    }

    function isBridgeInputRestricted(Restrictions storage _rs, address _input) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_BRIDGE_INPUT_BIT, _input);
    }

    function isBridgeOutputRestricted(Restrictions storage _rs, address _output) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_BRIDGE_OUTPUT_BIT, _output);
    }

    function isBridgeRouterRestricted(Restrictions storage _rs, address _router) internal view returns (bool) {
        return isRestricted(_rs, RESTRICT_BRIDGE_ROUTER_BIT, _router);
    }

    function isApproveMax(Restrictions storage _rs) internal view returns (bool) {
        return _rs.restrictionMask.getBit(APPROVE_MAX_BIT);
    }

    function isAutoRevoke(Restrictions storage _rs) internal view returns (bool) {
        return _rs.restrictionMask.getBit(AUTO_REVOKE_BIT);
    }
}
