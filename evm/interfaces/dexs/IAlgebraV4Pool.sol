// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IAlgebraV3PoolBase} from "./IAlgebraV3Pool.sol";

interface IAlgebraV4PoolBase is IAlgebraV3PoolBase {
    function burn(int24 bottomTick, int24 topTick, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1);
    function communityFeeLastTimestamp() external view returns (uint32);
    function communityVault() external view returns (address);
    function fee() external view returns (uint16 currentFee);
    function getCommunityFeePending() external view returns (uint128, uint128);
    function getReserves() external view returns (uint128, uint128);
    function isUnlocked() external view returns (bool unlocked);
    function mint(
        address leftoversRecipient,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 liquidityDesired,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);
    function nextTickGlobal() external view returns (int24);
    function plugin() external view returns (address);
    function prevTickGlobal() external view returns (int24);
    function setCommunityVault(address newCommunityVault) external;
    function setFee(uint16 newFee) external;
    function setPlugin(address newPluginAddress) external;
    function setPluginConfig(uint8 newConfig) external;
    function setTickSpacing(int24 newTickSpacing) external;
    function swap(address recipient, bool zeroToOne, int256 amountRequired, uint160 limitSqrtPrice, bytes calldata data)
        external
        returns (int256 amount0, int256 amount1);
    function swapWithPaymentInAdvance(
        address leftoversRecipient,
        address recipient,
        bool zeroToOne,
        int256 amountToSell,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    function tickTable(int16) external view returns (uint256);
    function tickTreeRoot() external view returns (uint32);
    function tickTreeSecondLayer(int16) external view returns (uint256);
}

interface IAlgebraV4PoolNoState is IAlgebraV4PoolBase {
    function ticks(int24)
        external
        view
        returns (
            uint256 liquidityTotal,
            int128 liquidityDelta,
            int24 prevTick,
            int24 nextTick,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token
        );
    function positions(bytes32)
        external
        view
        returns (
            uint256 liquidity,
            uint256 innerFeeGrowth0X128,
            uint256 innerFeeGrowth1X128,
            uint128 fees0,
            uint128 fees1
        );
}

interface IAlgebraV4Pool is IAlgebraV4PoolNoState {
    function globalState()
        external
        view
        returns (uint160 price, int24 tick, uint16 lastFee, uint8 pluginConfig, uint16 communityFee, bool unlocked);
    function safelyGetStateOfAMM()
        external
        view
        returns (
            uint160 sqrtPrice,
            int24 tick,
            uint16 lastFee,
            uint8 pluginConfig,
            uint128 activeLiquidity,
            int24 nextTick,
            int24 previousTick
        );
}
