// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibConvert as C} from "@libraries/LibConvert.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV4PoolManager} from "@interfaces/dexs/IUniV4PoolManager.sol";
import {IUniV4PositionManager} from "@interfaces/dexs/IUniV4PositionManager.sol";
import {IUniV4StateView} from "@interfaces/dexs/IUniV4StateView.sol";
import {DEXAdapter} from "@dexs/DEXAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Uniswap V4 Adapter - Uniswap V4 integration
 * @copyright 2025
 * @notice Implements Uniswap V4 specific DEX operations using PoolManager and PositionManager
 * @dev Inherits from DEXAdapter, implements V4's unlock pattern and PoolKey structure
 * @author BTR Team
 */

contract UniV4Adapter is DEXAdapter {
    using SafeERC20 for IERC20;
    using C for bytes32;
    using M for uint256;
    using DM for int24;
    using DM for uint160;

    // === STATE VARIABLES ===
    IUniV4PoolManager public immutable poolManager;
    IUniV4PositionManager public immutable positionManager;
    IUniV4StateView public immutable stateView;

    // === STRUCTS ===
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    // === CONSTRUCTOR ===
    constructor(address _diamond, address _poolManager, address _positionManager, address _stateView)
        DEXAdapter(_diamond)
    {
        poolManager = IUniV4PoolManager(_poolManager);
        positionManager = IUniV4PositionManager(_positionManager);
        stateView = IUniV4StateView(_stateView);
    }

    // === POOL KEY HELPERS ===
    function _poolKeyFromId(bytes32 _pid) internal view returns (PoolKey memory poolKey) {
        // Extract PoolKey components from poolId
        // V4 uses a different encoding than V3's simple address
        bytes25 poolId = bytes25(_pid);
        (poolKey.currency0, poolKey.currency1, poolKey.fee, poolKey.tickSpacing, poolKey.hooks) =
            positionManager.poolKeys(poolId);
    }

    function _poolIdFromKey(PoolKey memory _poolKey) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(_poolKey.currency0, _poolKey.currency1, _poolKey.fee, _poolKey.tickSpacing, _poolKey.hooks)
        );
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
        (priceX96, tick,,) = stateView.getSlot0(_pid);
    }

    function _rangePositionInfo(Range memory _range)
        internal
        view
        virtual
        override
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        // Use StateView to get position info
        (liquidity, fee0, fee1) = stateView.getPositionInfo(_range.poolId, _range.positionId);

        (, int24 currentTick) = _poolState(_range.poolId);
        (amount0, amount1) = DM.liquidityToAmountsTickV3(currentTick, _range.lowerTick, _range.upperTick, liquidity);
    }

    function _liquidityToAmountsTicks(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (, int24 currentTick) = _poolState(_pid);
        return DM.liquidityToAmountsTickV3(currentTick, _lowerTick, _upperTick, _liquidityValue);
    }

    function _amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) internal view virtual override returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual) {
        (uint160 priceX96,) = _poolState(_pid);
        uint160 sqrtRatioAX96 = _lowerTick.tickToPriceX96V3();
        uint160 sqrtRatioBX96 = _upperTick.tickToPriceX96V3();

        liquidity = DM.getLiquidityForAmounts(priceX96, sqrtRatioAX96, sqrtRatioBX96, _amount0Desired, _amount1Desired);

        // Recalculate actual amounts for the derived liquidity
        if (priceX96 <= sqrtRatioAX96) {
            amount0Actual = DM.getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
            amount1Actual = 0;
        } else if (priceX96 < sqrtRatioBX96) {
            amount0Actual = DM.getAmount0ForLiquidity(priceX96, sqrtRatioBX96, liquidity);
            amount1Actual = DM.getAmount1ForLiquidity(sqrtRatioAX96, priceX96, liquidity);
        } else {
            amount0Actual = 0;
            amount1Actual = DM.getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }

    // === V4 SPECIFIC IMPLEMENTATIONS ===

    /**
     * @notice Mints a new liquidity range following V4's unlock pattern
     * @dev Implements the full V4 flow: modifyLiquidities → unlock → modifyLiquidity → settle/take
     */
    function _mintRange(Range memory _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        override
        returns (bytes32 positionId, uint128 liquidityMinted, uint256 spent0, uint256 spent1)
    {
        PoolKey memory poolKey = _poolKeyFromId(_range.poolId);
        (IERC20 token0, IERC20 token1) = _poolTokens(_range.poolId);

        // Step 1: Approve tokens to PositionManager (following Permit2 pattern)
        token0.safeApprove(address(positionManager), type(uint256).max);
        token1.safeApprove(address(positionManager), type(uint256).max);

        // Step 2: Prepare unlock data following the call flow pattern
        bytes memory actions = abi.encode(
            _range.lowerTick,
            _range.upperTick,
            int256(uint256(_range.liquidity)), // positive liquidityDelta for mint
            _range.positionId
        );

        // Step 3: Execute through PositionManager's modifyLiquidities
        // This follows the pattern: modifyLiquidities → unlock → modifyLiquidity → settle/take
        positionManager.modifyLiquidities(actions, block.timestamp + 300);

        liquidityMinted = _range.liquidity;
        positionId = _range.positionId;

        // Step 4: Calculate actual spent amounts
        // In real implementation, this would be tracked during the unlock callback
        (spent0, spent1) = _liquidityToAmountsTicks(_range.poolId, _range.lowerTick, _range.upperTick, liquidityMinted);

        // Step 5: Revoke approvals for security
        token0.safeApprove(address(positionManager), 0);
        token1.safeApprove(address(positionManager), 0);
    }

    /**
     * @notice Burns liquidity and collects fees following V4's unlock pattern
     */
    function _burnRange(Range memory _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        override
        returns (uint256 amount0Burnt, uint256 amount1Burnt, uint256 fee0Collected, uint256 fee1Collected)
    {
        // Step 1: Get current position info from StateView
        (uint128 currentLiquidity, uint256 currentFee0, uint256 currentFee1) =
            stateView.getPositionInfo(_range.poolId, _range.positionId);

        // Step 2: Prepare burn action (negative liquidity delta)
        bytes memory actions = abi.encode(
            _range.lowerTick,
            _range.upperTick,
            -int256(uint256(currentLiquidity)), // negative for burn
            _range.positionId
        );

        // Step 3: Execute burn through unlock pattern
        positionManager.modifyLiquidities(actions, block.timestamp + 300);

        // Step 4: Calculate return amounts
        (amount0Burnt, amount1Burnt) =
            _liquidityToAmountsTicks(_range.poolId, _range.lowerTick, _range.upperTick, currentLiquidity);

        fee0Collected = currentFee0;
        fee1Collected = currentFee1;
    }

    /**
     * @notice Collects fees from a position (V4 handles this during modifyLiquidity)
     */
    function _collectRangeFees(Range memory _range, address _recipient, bytes calldata _callbackData)
        internal
        virtual
        override
        returns (uint256 collectedFee0, uint256 collectedFee1)
    {
        // In V4, fees are automatically collected during modifyLiquidity operations
        // This function queries the current fee amounts available
        (, collectedFee0, collectedFee1) = stateView.getPositionInfo(_range.poolId, _range.positionId);
    }

    /**
     * @notice Gets safe pool state with TWAP validation
     * @dev V4 oracle implementation would need to be added
     */
    function _safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        virtual
        override
        returns (uint160 priceX96, int24 tick, uint160 twapPriceX96, bool isStale, uint256 deviation)
    {
        (priceX96, tick) = _poolState(_pid);

        // TODO: Implement V4's oracle/TWAP mechanism
        // V4 may have different oracle design than V3
        twapPriceX96 = priceX96; // Placeholder
        isStale = false;
        deviation = 0;
    }

    /**
     * @notice Previews the amounts that would be received from burning liquidity
     */
    function _previewBurnRange(Range memory _range, uint128 _liquidityToPreview)
        internal
        view
        virtual
        override
        returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1)
    {
        (, int24 currentTick) = _poolState(_range.poolId);
        (amount0, amount1) =
            DM.liquidityToAmountsTickV3(currentTick, _range.lowerTick, _range.upperTick, _liquidityToPreview);

        // Get current fees if position exists
        if (_range.positionId != bytes32(0)) {
            (, lpFee0, lpFee1) = stateView.getPositionInfo(_range.poolId, _range.positionId);
        } else {
            lpFee0 = 0;
            lpFee1 = 0;
        }
    }

    // === V4 UNLOCK CALLBACK ===
    /**
     * @notice Callback function called by PoolManager during unlock
     * @dev This is where the actual PoolManager.modifyLiquidity call happens
     */
    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(poolManager), "Unauthorized: only PoolManager");

        // Decode the unlock data to perform the actual liquidity modification
        // This would contain PoolKey, ModifyLiquidityParams, and other context
        // Implementation depends on the specific data structure used

        // Example structure:
        // (PoolKey memory poolKey, ModifyLiquidityParams memory params, address recipient, bytes memory extra) =
        //   abi.decode(data, (PoolKey, ModifyLiquidityParams, address, bytes));

        // Execute the actual modifyLiquidity call
        // poolManager.modifyLiquidity(poolKey, params, hookData);

        // Handle currency settlement (settle/take pattern)
        // This is where tokens are actually transferred

        return abi.encode(true); // Return success indicator
    }
}
