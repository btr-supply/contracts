// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Base Test - Base contract for ALM integration tests
 * @copyright 2025
 * @notice Provides common setup and helper functions for ALM integration testing across different DEXs/chains
 * @dev Abstract contract to be inherited by specific test implementations
 * @author BTR Team
 */

import {Test, console} from "forge-std/Test.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ALMVault, Range, Rebalance, VaultInitParams, DEX, PoolInfo} from "@/BTRTypes.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {DEXAdapterFacet} from "@facets/abstract/DEXAdapterFacet.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {LibDEXMaths} from "@libraries/LibDEXMaths.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {LibMaths} from "@libraries/LibMaths.sol";

/**
 * @title ALMBaseTest
 * @notice Base test contract for ALM integration tests
 * @dev Chain-agnostic implementation - should be used with a chain-specific base test
 */
abstract contract ALMBaseTest is BaseDiamondTest {
    using SafeERC20 for IERC20;
    using BTRUtils for uint32;
    using BTRUtils for bytes32;

    // Price range constants
    uint256 constant LOWER_PRICE = 0.99e18; // $0.99 (token0/token1)
    uint256 constant UPPER_PRICE = 1.01e18; // $1.01 (token0/token1)
    uint16 constant RANGE_WEIGHT = 10000; // 100% weight to single range (10000 bps)

    // Facets
    ALMFacet public almFacet;
    DEXAdapterFacet public dexAdapterFacet;

    // Test state
    uint32 public vaultId;
    address public user;

    // Abstract functions - to be implemented by specific DEX tests
    function getToken0() internal view virtual returns (address);
    function getToken1() internal view virtual returns (address);
    function getTestStablePool() internal view virtual returns (address);
    function getTestPoolId() internal view virtual returns (bytes32);
    function getTestAdapter() internal view virtual returns (address);
    function getTestDEX() internal view virtual returns (DEX);
    function getTokenDecimals() internal view virtual returns (uint8, uint8);
    function getTokenWeiPerUnit() internal view virtual returns (uint256, uint256);
    function getDepositAmount() internal view virtual returns (uint256);

    function setUp() public virtual override {
        // Call parent setup to deploy diamond and initialize facets
        super.setUp();

        // Initialize interfaces
        almFacet = ALMFacet(address(diamond));
        dexAdapterFacet = DEXAdapterFacet(address(diamond));

        // Setup default user for testing
        user = makeAddr("user");
    }

    /**
     * @notice Setup DEX adapter
     */
    function _setupDEXAdapter() internal virtual {
        vm.startPrank(admin);
        DEX dex = getTestDEX();
        address adapter = getTestAdapter();

        if (adapter != address(0)) {
            almFacet.updateDexAdapter(dex, adapter);
        }
        vm.stopPrank();
    }

    /**
     * @notice Setup DEX pool with proper configuration
     */
    function _setupDEXPool() internal virtual {
        vm.startPrank(admin);
        bytes32 poolId = getTestPoolId();
        address pool = BTRUtils.toAddress(poolId);

        int24 tickSpacing = getPoolTickSpacing(getTestStablePool());
        uint24 fee = getPoolFee(getTestStablePool());

        registerPool(poolId, getTestDEX(), getToken0(), getToken1(), uint32(uint24(tickSpacing)), fee);
        vm.stopPrank();
    }

    /**
     * @notice Register a pool in the protocol
     */
    function registerPool(bytes32 poolId, DEX dex, address token0, address token1, uint32 tickSpacing, uint24 fee)
        internal
    {
        address poolAddress = BTRUtils.toAddress(poolId);
        PoolInfo memory poolInfo = PoolInfo({
            poolId: poolId,
            dex: dex,
            token0: token0,
            token1: token1,
            tickSize: tickSpacing,
            fee: uint32(fee)
        });

        (bool success, bytes memory returnData) = address(diamond).call(
            abi.encodeWithSignature(
                "setPoolInfo(bytes32,((bytes32,uint8,address,address,uint32,uint32)))", poolId, poolInfo
            )
        );

        require(success, "Pool registration failed");
    }

    /**
     * @notice Get tick spacing for a pool
     */
    function getPoolTickSpacing(address pool) internal view returns (int24) {
        return IUniV3Pool(pool).tickSpacing();
    }

    /**
     * @notice Get fee for a pool
     */
    function getPoolFee(address pool) internal view returns (uint24) {
        try IUniV3Pool(pool).fee() returns (uint24 fee) {
            return fee;
        } catch {
            return 100; // Default fee as fallback (1 basis point = 0.01%)
        }
    }

    /**
     * @notice Get range IDs for a vault
     */
    function getVaultRangeIds(uint32 _vaultId) internal view returns (bytes32[] memory) {
        // Direct access to vault ranges instead of calling almFacet.getVaultRanges
        return _vaultId.getVault().ranges;
    }

    /**
     * @notice Create a test vault with standard parameters
     */
    function createVault() internal returns (uint32) {
        (uint256 token0Unit, uint256 token1Unit) = getTokenWeiPerUnit();

        VaultInitParams memory params = VaultInitParams({
            name: "Test Vault",
            symbol: "TSTV",
            token0: getToken0(),
            token1: getToken1(),
            initAmount0: token0Unit,
            initAmount1: token1Unit,
            initShares: 1e18 // 1 full share
        });

        vm.startPrank(admin);
        uint32 newVaultId = almFacet.createVault(params);
        vm.stopPrank();

        return newVaultId;
    }

    /**
     * @notice Create a basic range for a vault
     */
    function createBasicRange() internal {
        createBasicRange(LOWER_PRICE, UPPER_PRICE);
    }

    /**
     * @notice Create a basic range with custom price boundaries
     */
    function createBasicRange(uint256 lowerPrice, uint256 upperPrice) internal {
        // Calculate ticks from prices using LibDEXMaths
        (int24 lowerTick, int24 upperTick) = getPriceTicks(getTestStablePool(), lowerPrice, upperPrice);

        Range[] memory ranges = new Range[](1);

        // Create single range with 100% weight
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: getTestPoolId(),
            weightBps: RANGE_WEIGHT,
            liquidity: 0,
            lowerTick: lowerTick,
            upperTick: upperTick
        });

        Rebalance memory rebalanceData = Rebalance({
            ranges: ranges,
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });

        vm.startPrank(manager);
        almFacet.rebalance(vaultId, rebalanceData);
        vm.stopPrank();
    }

    /**
     * @notice Deposit to a vault
     */
    function depositToVault(uint32 _vaultId, uint256 amount0, uint256 amount1) internal returns (uint256 shares) {
        vm.startPrank(user);
        (shares,,) = almFacet.deposit(_vaultId, amount0, amount1, user);
        vm.stopPrank();
        return shares;
    }

    /**
     * @notice Withdraw shares from a vault
     */
    function withdrawFromVault(uint32 _vaultId, uint256 shares) internal returns (uint256 amount0, uint256 amount1) {
        vm.startPrank(user);
        (amount0, amount1,,) = almFacet.withdraw(_vaultId, shares, user);
        vm.stopPrank();
        return (amount0, amount1);
    }

    /**
     * @notice Withdraw all shares from a vault
     */
    function withdrawAllShares(uint32 _vaultId) internal returns (uint256 amount0, uint256 amount1) {
        uint256 shares = almFacet.balanceOf(_vaultId, user);
        require(shares > 0, "No shares to withdraw");
        return withdrawFromVault(_vaultId, shares);
    }

    /**
     * @notice Convert price to ticks using LibDEXMaths
     */
    function getPriceTicks(address pool, uint256 lowerPrice, uint256 upperPrice)
        internal
        view
        returns (int24 lowerTick, int24 upperTick)
    {
        uint160 sqrtPriceX96 = uint160(LibMaths.sqrt(lowerPrice) * 2 ** 96 / LibMaths.sqrt(1e18));
        lowerTick = LibDEXMaths.getTickAtSqrtPrice(sqrtPriceX96);

        sqrtPriceX96 = uint160(LibMaths.sqrt(upperPrice) * 2 ** 96 / LibMaths.sqrt(1e18));
        upperTick = LibDEXMaths.getTickAtSqrtPrice(sqrtPriceX96);

        // Adjust ticks to be valid with the pool's tick spacing
        int24 spacing = getPoolTickSpacing(pool);
        lowerTick = LibDEXMaths.roundToTickSpacing(lowerTick, spacing, false);
        upperTick = LibDEXMaths.roundToTickSpacing(upperTick, spacing, true);

        return (lowerTick, upperTick);
    }

    /**
     * @notice Simulate fee accumulation (mock implementation)
     */
    function simulateFeeAccumulation() internal virtual {
        // Implemented by specific DEX tests if needed
    }

    /**
     * @notice Collect fees from ranges
     */
    function collectFees() internal {
        vm.startPrank(manager);

        // Use rebalance with empty range array to trigger fee collection
        Rebalance memory emptyRebalance = Rebalance({
            ranges: new Range[](0),
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });

        almFacet.rebalance(vaultId, emptyRebalance);
        vm.stopPrank();
    }

    /**
     * @notice Verify range positions in vault
     */
    function verifyRanges(string memory label) internal virtual {
        bytes32[] memory rangeIds = getVaultRangeIds(vaultId);
        require(rangeIds.length > 0, "No ranges found");

        uint256[] memory weights = almFacet.getWeights(vaultId);
        uint256 totalWeight = 0;

        for (uint256 i = 0; i < rangeIds.length; i++) {
            totalWeight += weights[i];
            (uint128 liquidity,,,,) = dexAdapterFacet.getPositionInfo(rangeIds[i]);
            require(liquidity > 0, "Range has no liquidity");
        }

        require(totalWeight == 10000, "Total weight should be 100%");

        // Verify vault has token balances
        (uint256 totalBalance0, uint256 totalBalance1) = almFacet.getTotalBalances(vaultId);
        require(totalBalance0 > 0 || totalBalance1 > 0, "Vault should have token balances");
    }
}
