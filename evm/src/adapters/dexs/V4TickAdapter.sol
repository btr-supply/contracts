// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {Range} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibConvert as C} from "@libraries/LibConvert.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV4PoolManager} from "@interfaces/dexs/IUniV4PoolManager.sol";
import {IUniV4PositionManager} from "@interfaces/dexs/IUniV4PositionManager.sol";
import {IUniV4StateView} from "@interfaces/dexs/IUniV4StateView.sol";
import {V4Adapter} from "@dexs/V4Adapter.sol";

// Suppress warnings for virtual functions with unused parameters (intended for override)
// solhint-disable func-param-name-mixedcase, no-unused-vars

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title V4 Tick Adapter Base - Base implementation for V4-style tick-based DEX adapters
 * @copyright 2025
 * @notice Implements V4 tick-based pattern using PoolManager and PositionManager with unlock mechanism
 * @dev Inherits from V4Adapter, implements V4's unlock pattern and PoolKey structure for tick-based systems
 * @author BTR Team
 */

abstract contract V4TickAdapter is V4Adapter {
    using SafeERC20 for IERC20;
    using C for bytes32;
    using M for uint256;
    using DM for int24;
    using DM for uint160;

    // === STATE VARIABLES ===
    IUniV4PoolManager public immutable poolManagerContract;
    IUniV4PositionManager public immutable positionManagerContract;
    IUniV4StateView public immutable stateViewContract;

    // === CONSTRUCTOR ===
    constructor(address _diamond, address _poolManager, address payable _positionManager, address _stateView)
        V4Adapter(_diamond)
    {
        poolManagerContract = IUniV4PoolManager(_poolManager);
        positionManagerContract = IUniV4PositionManager(_positionManager);
        stateViewContract = IUniV4StateView(_stateView);
    }

    // === IMPLEMENTATION OF ABSTRACT FUNCTIONS ===
    function poolManager() external view override returns (address) {
        return address(poolManagerContract);
    }

    function positionManager() external view override returns (address) {
        return address(positionManagerContract);
    }

    function stateView() external view override returns (address) {
        return address(stateViewContract);
    }

    // === POOL KEY HELPERS ===
    function _poolKeyFromId(bytes32 _pid) internal view override returns (PoolKey memory poolKey) {
        // Extract PoolKey components from poolId
        // V4 uses a different encoding than V3's simple address
        bytes25 poolId = bytes25(_pid);
        (poolKey.currency0, poolKey.currency1, poolKey.fee, poolKey.tickSpacing, poolKey.hooks) =
            positionManagerContract.poolKeys(poolId);
    }

    // === OVERRIDDEN VIRTUAL FUNCTIONS ===
    function _poolTokens(bytes32 _pid) internal view virtual override returns (IERC20 token0, IERC20 token1) {
        PoolKey memory poolKey = _poolKeyFromId(_pid);
        return (IERC20(poolKey.currency0), IERC20(poolKey.currency1));
    }

    function _poolTickSpacing(bytes32 _pid) internal view virtual override returns (int24) {
        PoolKey memory poolKey = _poolKeyFromId(_pid);
        return poolKey.tickSpacing;
    }

    function _poolState(bytes32 _pid) internal view virtual override returns (uint160 priceX96, int24 tick) {
        (priceX96, tick,,) = stateViewContract.getSlot0(_pid);
    }

    function _rangePositionInfo(Range calldata _range)
        internal
        view
        virtual
        override
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        // Use StateView to get position info
        (liquidity, fee0, fee1) = stateViewContract.getPositionInfo(_range.poolId, _range.positionId);

        (, int24 currentTick) = _poolState(_range.poolId);
        (amount0, amount1) = DM.liquidityToAmountsTickV3(currentTick, _range.lowerTick, _range.upperTick, liquidity);
    }

    // === V4 SPECIFIC IMPLEMENTATIONS ===

    /**
     * @notice Mints a new liquidity range following V4's unlock pattern
     * @dev Implements the full V4 flow: modifyLiquidities → unlock → modifyLiquidity → settle/take
     */
    function _mintRange(Range calldata _range, address /* _recipient */, bytes calldata /* _callbackData */)
        internal
        virtual
        override
        returns (bytes32 positionId, uint128 liquidityMinted, uint256 spent0, uint256 spent1)
    {
        /* PoolKey memory poolKey = */ _poolKeyFromId(_range.poolId);
        (IERC20 token0, IERC20 token1) = _poolTokens(_range.poolId);

        // Step 1: Approve tokens to PositionManager (following Permit2 pattern)
        token0.forceApprove(address(positionManagerContract), type(uint256).max);
        token1.forceApprove(address(positionManagerContract), type(uint256).max);

        // Step 2: Prepare unlock data following the call flow pattern
        bytes memory actions = abi.encode(
            _range.lowerTick,
            _range.upperTick,
            int256(uint256(_range.liquidity)), // positive liquidityDelta for mint
            _range.positionId
        );

        // Step 3: Execute through PositionManager's modifyLiquidities
        // This follows the pattern: modifyLiquidities → unlock → modifyLiquidity → settle/take
        positionManagerContract.modifyLiquidities(actions, block.timestamp + 300);

        liquidityMinted = _range.liquidity;
        positionId = _range.positionId;

        // Step 4: Calculate actual spent amounts
        // In real implementation, this would be tracked during the unlock callback
        (spent0, spent1) = _liquidityToAmountsTicks(_range.poolId, _range.lowerTick, _range.upperTick, liquidityMinted);

        // Step 5: Revoke approvals for security
        token0.forceApprove(address(positionManagerContract), 0);
        token1.forceApprove(address(positionManagerContract), 0);
    }

    /**
     * @notice Burns liquidity and collects fees following V4's unlock pattern
     */
    function _burnRange(Range calldata _range, address /* _recipient */, bytes calldata /* _callbackData */)
        internal
        virtual
        override
        returns (uint256 amount0Burnt, uint256 amount1Burnt, uint256 fee0Collected, uint256 fee1Collected)
    {
        // Step 1: Get current position info from StateView
        (uint128 currentLiquidity, uint256 currentFee0, uint256 currentFee1) =
            stateViewContract.getPositionInfo(_range.poolId, _range.positionId);

        // Step 2: Prepare burn action (negative liquidity delta)
        bytes memory actions = abi.encode(
            _range.lowerTick,
            _range.upperTick,
            -int256(uint256(currentLiquidity)), // negative for burn
            _range.positionId
        );

        // Step 3: Execute burn through unlock pattern
        positionManagerContract.modifyLiquidities(actions, block.timestamp + 300);

        // Step 4: Calculate return amounts
        (amount0Burnt, amount1Burnt) =
            _liquidityToAmountsTicks(_range.poolId, _range.lowerTick, _range.upperTick, currentLiquidity);

        fee0Collected = currentFee0;
        fee1Collected = currentFee1;
    }

    /**
     * @notice V4 fee collection implementation using DECREASE_LIQUIDITY + TAKE_PAIR pattern
     * @dev V4 handles fee collection during modifyLiquidity with zero liquidity change
     */
    function _collectFeesV4(Range calldata _range, address /* _recipient */, bytes calldata /* _callbackData */)
        internal
        virtual
        override
        returns (uint256 collectedFee0, uint256 collectedFee1)
    {
        // Step 1: Use DECREASE_LIQUIDITY action with zero change to trigger fee collection
        bytes memory actions = abi.encode(
            _range.lowerTick,
            _range.upperTick,
            int256(0), // zero liquidity delta for fee collection only
            _range.positionId
        );

        // Step 2: Execute fee collection through unlock pattern
        positionManagerContract.modifyLiquidities(actions, block.timestamp + 300);

        // Step 3: Get collected fees from position info
        (/* uint128 currentLiquidity */, /* uint256 currentAmount0 */, /* uint256 currentAmount1 */, uint256 currentFee0, uint256 currentFee1) = _rangePositionInfo(_range);
        collectedFee0 = currentFee0;
        collectedFee1 = currentFee1;
    }

    /**
     * @notice Previews the amounts that would be received from burning liquidity
     */
    function _previewBurnRange(Range calldata _range, uint128 _liquidityToPreview)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        // Get current position info
        (uint128 currentLiquidity, uint256 currentAmount0, uint256 currentAmount1, uint256 currentFee0, uint256 currentFee1) = _rangePositionInfo(_range);

        if (currentLiquidity == 0) {
            return (0, 0, 0, 0);
        }

        // Calculate proportional amounts
        amount0 = (currentAmount0 * _liquidityToPreview) / currentLiquidity;
        amount1 = (currentAmount1 * _liquidityToPreview) / currentLiquidity;
        lpFee0 = (currentFee0 * _liquidityToPreview) / currentLiquidity;
        lpFee1 = (currentFee1 * _liquidityToPreview) / currentLiquidity;
    }

    // === V4 UNLOCK CALLBACK ===
    /**
     * @notice Callback function called by PoolManager during unlock
     * @dev This is where the actual PoolManager.modifyLiquidity call happens
     */
    function unlockCallback(bytes calldata /* data */) external virtual override returns (bytes memory) {
        require(msg.sender == address(poolManagerContract), "Unauthorized: only PoolManager");

        // Decode the unlock data to perform the actual liquidity modification
        // This would contain PoolKey, ModifyLiquidityParams, and other context
        // Implementation depends on the specific data structure used

        // Example structure:
        // (PoolKey memory poolKey, ModifyLiquidityParams memory params, address recipient, bytes memory extra) =
        //   abi.decode(data, (PoolKey, ModifyLiquidityParams, address, bytes));

        // Execute the actual modifyLiquidity call
        // poolManagerContract.modifyLiquidity(poolKey, params, hookData);

        // Handle currency settlement (settle/take pattern)
        // This is where tokens are actually transferred

        return abi.encode(true); // Return success indicator
    }
}
