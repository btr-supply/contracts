// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ALMVault, Range, RebalanceParams, VaultInitParams, PoolInfo} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import {DEXAdapterFacet} from "@facets/abstract/DEXAdapterFacet.sol";
import {ALMInfoFacet} from "@facets/ALMInfoFacet.sol";
import {ALMProtectedFacet} from "@facets/ALMProtectedFacet.sol";
import {ALMUserFacet} from "@facets/ALMUserFacet.sol";
import {BTRSwapUtils} from "./BTRSwapUtils.t.sol";
import {TreasuryFacet} from "@facets/TreasuryFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Base Test - Base contract for ALM integration tests
 * @copyright 2025
 * @notice Provides common setup and helper functions for ALM integration testing across different DEXs/chains
 * @dev Abstract base for ALM integration tests:
- Deploys diamond, registers adapters/pools, and initializes vaults
- Defines virtual methods: `weights()`, `ranges()`, `getToken0()`, `getToken1()`, `pools()`
- Extended by BNB-specific and other chain tests. Covers core user flows (`deposit`, `withdraw`) and rebalance paths. Validates `nonReentrant` and `whenNotPaused` modifiers implicitly

 * @author BTR Team
 */

// import {Test, console} from "forge-std/Test.sol"; // inherited from BaseDiamondTest

// import {ALMFacet} from "@facets/ALMFacet.sol"; // Replaced with specific facets

abstract contract BaseALMTest is BaseDiamondTest {
    using SafeERC20 for IERC20;
    using U for address;
    using U for uint32;
    using U for bytes32;
    using C for bytes32;
    using C for address;

    // Facets
    ALMUserFacet public almUser;
    ALMProtectedFacet public almProtected;
    ALMInfoFacet public almInfo;
    DEXAdapterFacet public dex;
    TreasuryFacet public treasury;

    // Test state
    uint32 public vid;

    // To be implemented by inheriting chain/DEX specific tests
    // function dexs() internal view virtual returns (DEX[] memory); // REMOVED
    function adapterst() internal view virtual returns (address[] memory); // ADDED - To be implemented by concrete tests
    function pools() internal view virtual returns (address[] memory v3, bytes32[] memory v4);
    function narrowRange() internal view virtual returns (uint256 lowerPrice, uint256 upperPrice);
    function wideRange() internal view virtual returns (uint256 lowerPrice, uint256 upperPrice);
    function tokens() internal view virtual returns (address, address);
    function weights() internal view virtual returns (uint16[] memory);
    function depositSingle0() internal view virtual returns (uint256);

    function v3Pools() internal view virtual returns (address[] memory v3) {
        (v3,) = pools();
    }

    function v4Pools() internal view virtual returns (bytes32[] memory v4) {
        (, v4) = pools();
    }

    function emptyRebalance() internal returns (RebalanceParams memory) {
        return RebalanceParams({
            ranges: new RangeParams[](0),
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });
    }

    function decimals() internal view returns (uint8, uint8) {
        (address token0, address token1) = tokens();
        return (IERC20Metadata(token0).decimals(), IERC20Metadata(token1).decimals());
    }

    function depositWei0() internal view returns (uint256) {
        (uint256 unit0,) = weiPerUnit();
        return depositSingle0() * unit0;
    }

    function depositWei1() internal returns (uint256) {
        // Compute matching token1 amount based on target ratio for a deposit of depositWei0()
        uint256 depositSingle0Wei = depositWei0();
        // Use almView for preview functions
        (uint256 amount1,,,) = vid.previewDepositExact1(depositSingle0Wei);
        return amount1;
    }

    function depositWei() internal returns (uint256 amount0, uint256 amount1) {
        amount0 = depositWei0();
        amount1 = depositWei1();
    }

    function weiPerUnit() internal view returns (uint256, uint256) {
        (uint8 d0, uint8 d1) = decimals();
        return (10 ** d0, 10 ** d1);
    }

    function v3PoolIdiam() internal view virtual returns (bytes32[] memory ids) {
        address[] memory p = v3Pools();
        ids = new bytes32[](p.length);
        for (uint256 i = 0; i < p.length; i++) {
            ids[i] = p[i].toBytes32();
        }
    }

    function v4PoolIdiam() internal view virtual returns (bytes32[] memory ids) {
        return v4Pools();
    }

    function poolIdiam() internal view virtual returns (bytes32[] memory ids) {
        (address[] memory v3, bytes32[] memory v4) = pools();
        ids = new bytes32[](v3.length + v4.length);

        // Add V3 pool IDs
        for (uint256 i = 0; i < v3.length; i++) {
            ids[i] = v3[i].toBytes32();
        }

        // Add V4 pool IDs
        for (uint256 i = 0; i < v4.length; i++) {
            ids[i + v3.length] = v4[i];
        }
    }

    function registerDEXAdapterst() internal virtual {
        // This function is now largely obsolete as adapters are set in PoolInfo directly
        // during setPoolInfo. It used to call almProtected.setDexAdapter which is now removed.
        // Concrete test implementations might need to deploy/register adapter contracts themselves if needed for other reasons.
    }

    function registerV3Pools() internal virtual {
        vm.startPrank(admin);
        address[] memory poolsV3 = v3Pools();
        address[] memory _currentAdapters = adapterst(); // USING the new adapterst() function
        if (poolsV3.length != _currentAdapters.length) {
            revert("Pools and adapters array length mismatch in test setup");
        }
        (address token0, address token1) = tokens();
        for (uint256 i = 0; i < poolsV3.length; i++) {
            address pool = poolsV3[i];
            bytes32 poolId = pool.toBytes32();
            uint24 tickSpacing = uint24(IUniV3Pool(pool).tickSpacing()); // Ensure tickSpacing is uint24
            uint32 fee = IUniV3Pool(pool).fee();
            almProtected.setPoolInfo(poolId, _currentAdapters[i], token0, token1, tickSpacing, fee); // UPDATED call
        }
        vm.stopPrank();
    }

    function setUp() public virtual override {
        super.setUp(); // fork+deploy diamond and initialize facets

        almUser = ALMUserFacet(diamond);
        almProtected = ALMProtectedFacet(diamond);
        almInfo = ALMInfoFacet(diamond);
        // dex = DEXAdapterFacet(diamond); // COMMENTED OUT - DEXAdapterFacet changed and DEX enum removed
        treasury = TreasuryFacet(diamond);

        // registerDEXAdapterst(); // Call REMOVED
        registerV3Pools(); // register V3 pools

        (address token0, address token1) = tokens();
        (uint256 toDepositSingle0Wei, uint256 toDepositSingle1Wei) = depositWei();

        deal(token0, user, toDepositSingle0Wei); // allocate test deposit tokens to user
        deal(token1, user, toDepositSingle1Wei);

        vm.startPrank(user);
        IERC20(token0).approve(diamond, type(uint256).max); // approve diamond to spend tokens
        IERC20(token1).approve(diamond, type(uint256).max);
        vm.stopPrank();
    }

    function createVault() internal returns (uint32) {
        (uint256 init0, uint256 init1) = depositWei();
        (address token0, address token1) = tokens();
        VaultInitParams memory params = VaultInitParams({
            name: "Test Vault",
            symbol: "TSTV",
            token0: token0,
            token1: token1,
            init0: init0,
            init1: init1,
            initShares: 1e18 // 1 full share
        });

        vm.prank(admin);
        vid = almProtected.createVault(params);

        vm.prank(admin);
        almProtected.setWeights(vid, weights());
        return vid;
    }

    function openV3Ranges(uint256 min, uint256 max) internal virtual {
        address[] memory poolAddresses = v3Pools();
        uint16[] memory _weights = weights(); // Assumes weights matches pools length
        RangeParams[] memory rangesToMint = new RangeParams[](poolAddresses.length); // Changed to RangeParams[]

        for (uint256 i = 0; i < poolAddresses.length; i++) {
            bytes32 pid = BTRUtils.toBytes32(poolAddresses[i]);
            // PoolInfo memory poolInfo = almInfo.poolInfo(pid); // This was already correct
            // (int24 lowerTick, int24 upperTick) =
            // DM.priceRangeToTicks(min, max, int24(poolInfo.tickSpacing)); // This logic is for minting actual Range structs
            rangesToMint[i] = RangeParams({ // Changed to RangeParams
                poolId: pid,
                lowerPrice: min, // Directly using min/max for RangeParams
                upperPrice: max,
                weightBp: _weights[i]
            });
        }

        vm.prank(keeper);
        // The rebalance function in ALMProtectedFacet expects RebalanceParams
        // and emptyRebalance() now correctly returns RebalanceParams.
        // However, the rebalance function itself in LibALMProtected.rebalance takes RebalanceParams.
        // The ranges inside RebalanceParams are RangeParams[], so this should align.
        // The mintRange/mintRanges functions inside LibALMBase take RangeParams/RebalanceParams.
        RebalanceParams memory rbParams = RebalanceParams({
            ranges: rangesToMint,
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });
        almProtected.rebalance(vid, rbParams);
    }

    function collectFees() internal {
        vm.prank(manager);
        almProtected.rebalance(vid, emptyRebalance());
    }

    function verifyRanges() internal virtual {
        bytes32[] memory rids = vid.vaultRangeIdiam();
        require(rids.length > 0, "No ranges found");

        uint16[] memory weightsBp = vid.weights();
        uint256 totalWeightBp = 0;

        for (uint256 i = 0; i < rids.length; i++) {
            totalWeightBp += weightsBp[i];
            (uint128 liquidity,,,,) = dex.positionInfo(rids[i]);
            require(liquidity > 0, "Range has no liquidity");
        }

        require(totalWeightBp == M.BPS, "Vault ranges total weight != 100%");
        (uint256 balance0, uint256 balance1) = almInfo.lpBalances(vid);
        require(balance0 > 0 || balance1 > 0, "Vault should have positive token balances");
    }

    function depositForShares(uint256 sharesAmount) internal {
        (address token0, address token1) = tokens();
        (uint256 preDepositShares) = almInfo.balanceOf(vid, user);

        (uint256 preDepositSingle0, uint256 preDepositSingle1) =
            (IERC20(token0).balanceOf(user), IERC20(token1).balanceOf(user));
        (
            uint256 expectedDepositSingle0,
            uint256 expectedDepositSingle1,
            uint256 expectedEntryFee00,
            uint256 expectedEntryFee01
        ) = almInfo.previewDeposit(vid, sharesAmount);
        (uint256 expectedMintedShares, uint256 expectedEntryFee10, uint256 expectedEntryFee11) =
            almInfo.previewDeposit(vid, expectedDepositSingle0, expectedDepositSingle1);
        require(expectedEntryFee00 == expectedEntryFee10, "Token 1 entry fees don't match between previews");
        require(expectedEntryFee01 == expectedEntryFee11, "Token 2 entry fees don't match between previews");
        require(expectedDepositSingle0 > preDepositSingle0, "Token 0 balance too low");
        require(expectedDepositSingle1 > preDepositSingle1, "Token 1 balance too low");

        vm.prank(user);
        (uint256 spent0, uint256 spent1) = almUser.deposit(vid, sharesAmount, user);
        (uint256 postDepositSingle0, uint256 postDepositSingle1) =
            (IERC20(token0).balanceOf(user), IERC20(token1).balanceOf(user));
        (uint256 pendingFees1, uint256 pendingFees2) = treasury.almPendingFees(vid);
        require(
            postDepositSingle0 == preDepositSingle0 - expectedDepositSingle0, "Token 0 deposit does not match preview"
        );
        require(
            postDepositSingle1 == preDepositSingle1 - expectedDepositSingle1, "Token 1 deposit does not match preview"
        );
        require(
            postDepositSingle0 + expectedEntryFee00 == preDepositSingle0, "Token 0 entry fee does not match preview"
        );
        require(
            postDepositSingle1 + expectedEntryFee01 == preDepositSingle1, "Token 1 entry fee does not match preview"
        );
    }

    function testVaultLifecycle() internal {
        uint32 id = createVault(); // createVault + setWeights on new vid
        (address token0, address token1) = tokens();
        (uint256 min, uint256 max) = narrowRange(); // default test range: narrow
        openV3Ranges(min, max); // open ranges (deploy initial liquidity on DEXs)
        verifyRanges();

        (uint256 preDepositSingle0, uint256 preDepositSingle1) =
            (IERC20(token0).balanceOf(user), IERC20(token1).balanceOf(user));

        vm.prank(user); // use default test user
        (uint256 spent0, uint256 spent1) = id.deposit(1e18, user); // deposit for 1 share
        require(id.balanceOf(user) == 1e18, "User should have exactly 1 share");

        (uint256 toDepositSingle0Wei, uint256 toDepositSingle1Wei) = depositWei();
        (uint256 expectedMintedShares, uint256 expectedEntryFee00, uint256 expectedEntryFee01) =
            id.previewDeposit(toDepositSingle0Wei, toDepositSingle1Wei);
        (
            uint256 expectedDepositSingle0,
            uint256 expectedDepositSingle1,
            uint256 expectedEntryFee10,
            uint256 expectedEntryFee11
        ) = id.previewDeposit(expectedMintedShares);
        require(
            toDepositSingle0Wei == expectedDepositSingle0, "Deposit amount 0 should match expected deposit amount 0"
        );
        require(
            toDepositSingle1Wei == expectedDepositSingle1, "Deposit amount 1 should match expected deposit amount 1"
        );
        require(expectedEntryFee00 == expectedEntryFee10, "Token 1 entry fees don't match between previews");
        require(expectedEntryFee01 == expectedEntryFee11, "Token 2 entry fees don't match between previews");

        vm.prank(user);
        (uint256 mintedShares) = id.deposit(toDepositSingle0Wei, toDepositSingle1Wei, user);
        uint256 userBalance = id.balanceOf(user);
        require(mintedShares == expectedMintedShares, "Minted shares should match expected shares");
        require(id.balanceOf(user) == (expectedMintedShares + 1e18), "User should have exactly 1 + expected shares");

        (
            uint256 expectedWithdraw0,
            uint256 expectedWithdrawSingle1,
            uint256 expectedExitFee00,
            uint256 expectedExitFee01
        ) = id.previewWithdraw(id.balanceOf(user));
        (uint256 expectedBurntShares, uint256 expectedExitFee10, uint256 expectedExitFee11) =
            id.previewWithdraw(expectedWithdraw0, expectedWithdrawSingle1);
        require(expectedExitFee00 == expectedExitFee10, "Token 1 exit fees don't match between previews");
        require(expectedExitFee01 == expectedExitFee11, "Token 2 exit fees don't match between previews");

        vm.prank(user);
        (uint256 withdraw0, uint256 withdrawSingle1) = id.withdraw(id.balanceOf(user), user);
    }

    function testRebalanceWithSwaps() public virtual {
        // 1. Create vault
        vid = createVault();
        (address token0, address token1) = tokens();

        // 2. Open initial ranges (narrow range)
        (uint256 narrowMin, uint256 narrowMax) = narrowRange();
        uint16[] memory initialWeights = weights();
        RangeParams[] memory initialRanges = new RangeParams[](1);
        bytes32[] memory initialPoolIds = poolIdiam();

        PoolInfo memory poolInfo = almInfo.poolInfo(initialPoolIds[0]);

        initialRanges[0] = RangeParams({
            poolId: initialPoolIds[0],
            lowerPrice: narrowMin,
            upperPrice: narrowMax,
            weightBp: initialWeights[0]
        });

        RebalanceParams memory initialRebalance = RebalanceParams({
            ranges: initialRanges,
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });
        vm.prank(keeper);
        almProtected.rebalance(vid, initialRebalance);
        verifyRanges();

        // 3. Simulate token imbalance (e.g., vault has excess token0)
        uint256 excessToken0Amount = 100 * (10 ** IERC20Metadata(token0).decimals()); // 100 token0
        deal(token0, diamond, IERC20(token0).balanceOf(diamond) + excessToken0Amount);

        (uint256 vaultCash0Before, uint256 vaultCash1Before) = almInfo.cash(vid);
        console.log(
            "Vault cash before swap: token0=%s (%s decimals), token1=%s (%s decimals)",
            vaultCash0Before,
            IERC20Metadata(token0).decimals(),
            vaultCash1Before,
            IERC20Metadata(token1).decimals()
        );

        // 4. Define new target ranges (wide range)
        (uint256 wideMin, uint256 wideMax) = wideRange();
        RangeParams[] memory targetRanges = new RangeParams[](1);
        (int24 wideLowerTick, int24 wideUpperTick) = DM.priceRangeToTicks(wideMin, wideMax, int24(poolInfo.tickSpacing));

        targetRanges[0] = RangeParams({
            poolId: initialPoolIds[0],
            lowerPrice: wideMin,
            upperPrice: wideMax,
            weightBp: initialWeights[0]
        });

        // 5. Prepare Rebalance struct with swap parameters using btr-swap CLI
        address[] memory swapInputs = new address[](1);
        swapInputs[0] = token0;

        uint256 amountToSwap = vaultCash0Before / 2; // Swap half of available token0 cash

        // Generate swap calldata using btr-swap CLI (similar to BTRSwapTest.t.sol)
        (address swapRouter, address approveTo, uint256 value, bytes memory swapData) =
            BTRSwapUtils.generateSwapData(token0, token1, amountToSwap);

        address[] memory swapRouters = new address[](1);
        swapRouters[0] = swapRouter;

        bytes[] memory swapDataArray = new bytes[](1);
        swapDataArray[0] = swapData;

        console.log("Attempting to swap %s of token0 for token1 via router %s", amountToSwap, swapRouter);

        RebalanceParams memory rebalanceWithSwap = RebalanceParams({
            ranges: targetRanges,
            swapInputs: swapInputs,
            swapRouters: swapRouters,
            swapData: swapDataArray
        });

        // 6. Call rebalance
        vm.prank(keeper);
        (uint256 protocolFees0, uint256 protocolFees1) = almProtected.rebalance(vid, rebalanceWithSwap);

        // 7. Add assertions
        (uint256 vaultCash0After, uint256 vaultCash1After) = almInfo.cash(vid);
        console.log("Vault cash after swap: token0=%s, token1=%s", vaultCash0After, vaultCash1After);
        console.log("Protocol fees: token0=%s, token1=%s", protocolFees0, protocolFees1);

        assertTrue(vaultCash0After < vaultCash0Before, "Cash0 should decrease after swap");
        assertTrue(vaultCash1After > vaultCash1Before, "Cash1 should increase after swap");

        bytes32[] memory ridsAfter = vid.vaultRangeIdiam();
        require(ridsAfter.length > 0, "No ranges found after rebalance");
        (uint128 liquidityAfter,,,,) = dex.positionInfo(ridsAfter[0]);
        assertTrue(liquidityAfter > 0, "New range should have liquidity");

        RangeParams memory rangeAfterRebalance = almInfo.range(ridsAfter[0]);
        assertTrue(rangeAfterRebalance.lowerPrice == wideMin, "Lower price should match wide range");
        assertTrue(rangeAfterRebalance.upperPrice == wideMax, "Upper price should match wide range");
    }
}
