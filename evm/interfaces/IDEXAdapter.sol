// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Range} from "@/BTRTypes.sol"; // Import Range struct
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Range type might still be useful for structs passed around, but not for direct storage access via _rid.range()
// import {Range} from "@/BTRTypes.sol";
interface IDEXAdapter {
    // --- View functions --- //
    function decimals() external view returns (uint8);
    function poolTokens(bytes32 _pid) external view returns (IERC20 token0, IERC20 token1);
    function poolPrice(bytes32 _pid) external view returns (uint256 price);
    function poolState(bytes32 _pid) external view returns (uint160 sqrtPriceX96, int24 tick);

    function safePoolState(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint160 twapSqrtPriceX96, bool isStale, uint256 deviation);

    function safePoolPrice(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (uint256 price);

    function isPoolPriceStale(bytes32 _pid, uint32 _lookback, uint256 _maxDeviationBp)
        external
        view
        returns (bool isStale);

    // Removed checkStalePrice as it's an internal helper, not part of external interface typically.
    // It can be implemented in the abstract DEXAdapter or concrete adapters if needed.

    function rangePositionInfo(
        Range calldata _range // Includes pid, owner, lowerTick, upperTick, positionId
    ) external view returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    function liquidityToAmountsTicks( // Keep this signature as per user's change
    bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidityValue)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function liquidityToAmounts(bytes32 _rid, uint128 _liquidityValue)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    // Renamed liquidityToAmountsTicks to just liquidityToAmounts as it's the primary way now.
    // Removed amountsToLiquiditySqrt - amountsToLiquidity is more general.

    function amountsToLiquidity(
        bytes32 _pid,
        int24 _lowerTick,
        int24 _upperTick,
        uint256 _amount0Desired,
        uint256 _amount1Desired
    ) external view returns (uint128 liquidity, uint256 amount0Actual, uint256 amount1Actual);

    function liquidityRatio0(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        external
        view
        returns (uint256 ratio0);

    function liquidityRatio1(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint128 _liquidity)
        external
        view
        returns (uint256 ratio1);

    function lpPrice0AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        external
        view
        returns (uint256 lpPrice);

    function lpPrice1AtPrice(bytes32 _pid, int24 _lowerTick, int24 _upperTick, uint256 _price)
        external
        view
        returns (uint256 lpPrice);

    function lpPrice0(bytes32 _pid, int24 _lowerTick, int24 _upperTick) external view returns (uint256 lpPrice);

    function lpPrice1(bytes32 _pid, int24 _lowerTick, int24 _upperTick) external view returns (uint256 lpPrice);

    function previewBurnRange(
        Range calldata _range, // Includes pid, owner, lowerTick, upperTick, positionId
        uint128 _liquidityToPreview
    ) external view returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1);

    // --- State-changing functions --- //

    function mintRange(
        Range calldata _range, // Contains pid, recipient (as owner), ticks, positionId (if new), desired liquidity
        address _recipient, // Actual recipient of funds/NFT, or for callback context
        bytes calldata _callbackData
    )
        external
        returns (
            bytes32 positionId, // Actual positionId created or confirmed
            uint128 liquidityMinted,
            uint256 amount0,
            uint256 amount1
        );

    function burnRange(
        Range calldata _range, // Contains pid, owner, ticks, positionId, liquidityToBurn
        address _recipient, // Actual recipient of funds from burn
        bytes calldata _callbackData
    ) external returns (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1);

    function collectRangeFees(
        Range calldata _range, // Contains pid, owner (for identifying position), ticks, positionId
        address _recipient, // Actual recipient of fees
        bytes calldata _callbackData
    ) external returns (uint256 collectedFee0, uint256 collectedFee1);
}
