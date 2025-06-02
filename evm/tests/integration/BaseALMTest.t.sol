// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {ALMVault, Range, RebalanceParams, VaultInitParams, PoolInfo, RangeParams, MintProceeds, BurnProceeds} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.gen.t.sol";
import {ALMInfoFacet} from "@facets/ALMInfoFacet.sol";
import {ALMProtectedFacet} from "@facets/ALMProtectedFacet.sol";
import {ALMUserFacet} from "@facets/ALMUserFacet.sol";
import {BTRSwapUtils} from "./BTRSwapUtils.t.sol";
import {TreasuryFacet} from "@facets/TreasuryFacet.sol";
import {InfoFacet} from "@facets/InfoFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Base Test - Comprehensive ALM integration testing
 * @notice Organized test flows for vault lifecycle, deposits, withdrawals, and rebalancing
 * @dev Abstract base for chain-specific ALM tests covering user and protocol flows
 */

abstract contract BaseALMTest is BaseDiamondTest {
    using SafeERC20 for IERC20;
    using U for address;
    using U for uint32;
    using U for bytes32;
    using C for bytes32;
    using C for address;

    // Core facets
    ALMUserFacet public almUser;
    ALMProtectedFacet public almProtected;
    ALMInfoFacet public almInfo;
    TreasuryFacet public treasuryFacet;
    InfoFacet public infoFacet;

    // Test state - shortened names
    uint32 public vid; // vaultId
    address internal t0; // token0
    address internal t1; // token1
    uint8 internal d0; // decimals0
    uint8 internal d1; // decimals1

    // Virtual functions for concrete implementations
    function adapters() internal view virtual returns (address[] memory);
    function pools() internal view virtual returns (address[] memory v3, bytes32[] memory v4);
    function narrowRange() internal view virtual returns (uint256 lower, uint256 upper);
    function wideRange() internal view virtual returns (uint256 lower, uint256 upper);
    function _tokens() internal view virtual returns (address token0, address token1);
    function weights() internal view virtual returns (uint16[] memory);
    function depositSingle0() internal view virtual returns (uint256);

    // Compact helper functions
    function _bal(address usr) internal view returns (uint256, uint256) { return (IERC20(t0).balanceOf(usr), IERC20(t1).balanceOf(usr)); }
    function _shares() internal view returns (uint256) { return almInfo.balanceOf(vid, user); }
    function _cash() internal view returns (uint256, uint256) { return (almInfo.cash0(vid), almInfo.cash1(vid)); }
    function _v3() internal view virtual returns (address[] memory v3) { (v3,) = pools(); }
    function _v4() internal view virtual returns (bytes32[] memory v4) { (, v4) = pools(); }
    function _req(bool cond, string memory err) internal pure { require(cond, err); }
    function _reqGt0(uint256 val, string memory err) internal pure { require(val > 0, err); }

    function _depositAmts() internal view returns (uint256 amt0, uint256 amt1) {
        amt0 = depositSingle0() * (10 ** d0);
        if (amt0 == 0) return (0, 0);
        (amt1,,,) = almInfo.previewDepositExact0(vid, amt0, user);
    }

    // Helper functions for common operations
    function _getTokens() internal view returns (address, address) { return (t0, t1); }
    function _getDecimals() internal view returns (uint8, uint8) { return (d0, d1); }
    function _getUserShares() internal view returns (uint256) { return almInfo.balanceOf(vid, user); }
    function _getVaultCash() internal view returns (uint256 cash0, uint256 cash1) { return (almInfo.cash0(vid), almInfo.cash1(vid)); }

    function v3Pools() internal view virtual returns (address[] memory v3) { (v3,) = pools(); }
    function v4Pools() internal view virtual returns (bytes32[] memory v4) { (, v4) = pools(); }

    function emptyRebalance() internal pure returns (RebalanceParams memory) {
        return RebalanceParams({ranges: new RangeParams[](0), swapInputs: new address[](0), swapRouters: new address[](0), swapData: new bytes[](0)});
    }

    function _depositAmount0Wei() internal view returns (uint256) { return depositSingle0() * (10 ** d0); }

    function _depositAmount1Wei() internal view returns (uint256) {
        uint256 amt0 = _depositAmount0Wei();
        if (amt0 == 0) return 0;
        (uint256 amt1,,,) = almInfo.previewDepositExact0(vid, amt0, user); // Corrected: previewDepositExact0 returns 4 values
        return amt1;
    }

    function _depositAmountsWei() internal view returns (uint256 amt0, uint256 amt1) {
        amt0 = _depositAmount0Wei();
        amt1 = _depositAmount1Wei();
    }

    // Grouped validation functions
    function _requirePositive(uint256 val, string memory err) internal pure { require(val > 0, err); }
    function _requireNonZero(uint256 val, string memory err) internal pure { require(val != 0, err); }
    function _requireBalance(address tokenAddr, address usr, uint256 expected, string memory err) internal view {
        assertEq(IERC20(tokenAddr).balanceOf(usr), expected, err);
    }

    function _fetchDecimals() internal view returns (uint8 dec0, uint8 dec1) {
        return (IERC20Metadata(t0).decimals(), IERC20Metadata(t1).decimals());
    }

    function _poolIds() internal view virtual returns (bytes32[] memory ids) {
        (address[] memory v3, bytes32[] memory v4) = pools();
        ids = new bytes32[](v3.length + v4.length);
        for (uint256 i = 0; i < v3.length; i++) ids[i] = v3[i].toBytes32();
        for (uint256 i = 0; i < v4.length; i++) ids[i + v3.length] = v4[i];
    }

    function registerV3Pools() internal virtual {
        vm.startPrank(admin);
        address[] memory pV3 = _v3();
        address[] memory adaps = adapters();
        _req(pV3.length == adaps.length, "Pools/adapters length mismatch");

        (address tok0, address tok1) = _tokens();
        for (uint256 i = 0; i < pV3.length; i++) {
            bytes32 pid = pV3[i].toBytes32();
            int24 tickSp = IUniV3Pool(pV3[i]).tickSpacing();
            uint24 fee = IUniV3Pool(pV3[i]).fee();
            almProtected.setPoolInfo(pid, adaps[i], tok0, tok1, uint24(tickSp), fee);
        }
        vm.stopPrank();
    }

    function setUp() public virtual override {
        super.setUp();
        almUser = ALMUserFacet(diamond);
        almProtected = ALMProtectedFacet(diamond);
        almInfo = ALMInfoFacet(diamond);
        treasuryFacet = TreasuryFacet(diamond);
        infoFacet = InfoFacet(diamond);

        (t0, t1) = _tokens();
        (d0, d1) = (IERC20Metadata(t0).decimals(), IERC20Metadata(t1).decimals());
        registerV3Pools();

        (uint256 dep0, uint256 dep1) = _depositAmts();
        deal(t0, user, dep0 * 2);
        deal(t1, user, dep1 * 2);

        vm.startPrank(user);
        IERC20(t0).approve(diamond, type(uint256).max);
        IERC20(t1).approve(diamond, type(uint256).max);
        vm.stopPrank();
    }

    function createVault() internal returns (uint32 vaultId) {
        (uint256 init0, uint256 init1) = _depositAmts();
        VaultInitParams memory params = VaultInitParams({
            name: "TestVault", symbol: "TSTV", token0: t0, token1: t1,
            init0: init0, init1: init1, initShares: 1e18
        });

        vm.prank(admin);
        vaultId = almProtected.createVault(params);
        vm.prank(admin);
        almProtected.setWeights(vaultId, weights());
        vid = vaultId;
    }

    function openV3Ranges(uint256 minP, uint256 maxP) internal virtual {
        address[] memory pList = _v3();
        uint16[] memory w = weights();
        _req(pList.length == w.length, "Pools/weights length mismatch");

        RangeParams[] memory ranges = new RangeParams[](pList.length);
        for (uint256 i = 0; i < pList.length; i++) {
            bytes32 pid = C.toBytes32(pList[i]);
            PoolInfo memory pInfo = almInfo.poolInfo(pid);
            _reqGt0(uint256(uint16(pInfo.tickSize)), "Tick size not set");

            (int24 lowerTick, int24 upperTick) = DM.priceX96RangeToTicks(
                DM.priceToPriceX96(minP), DM.priceToPriceX96(maxP), int24(pInfo.tickSize), pInfo.inverted
            );
            ranges[i] = RangeParams({
                poolId: pid, lowerPriceX96: DM.tickToPriceX96V3(lowerTick), upperPriceX96: DM.tickToPriceX96V3(upperTick),
                liquidity: 0, weightBp: w[i]
            });
        }

        vm.prank(keeper);
        almProtected.rebalance(vid, RebalanceParams({ranges: ranges, swapInputs: new address[](0), swapRouters: new address[](0), swapData: new bytes[](0)}));
    }

    function verifyRanges() internal virtual {
        bytes32[] memory rids = almInfo.vaultRangeIds(vid);
        _reqGt0(rids.length, "No ranges found");

        uint16[] memory wBp = almInfo.weights(vid);
        uint256 totalW = 0;
        for (uint256 i = 0; i < rids.length; i++) {
            totalW += wBp[i];
            _reqGt0(almInfo.range(rids[i]).liquidity, "Range has no liquidity");
        }

        assertEq(totalW, M.BPS, "Vault ranges total weight != 100%");
        (uint256 bal0, uint256 bal1) = almInfo.lpBalances(vid);
        assertTrue(bal0 > 0 || bal1 > 0, "Vault should have positive LP token balances");
    }

    function collectFees() internal {
        vm.prank(manager);
        almProtected.rebalance(vid, emptyRebalance());
    }

    function depositForShares(uint256 sharesAmount) internal {
        (address tok0, address tok1) = _getTokens();
        uint256 preShares = _getUserShares();
        (uint256 preBal0, uint256 preBal1) = _bal(user);

        (uint256 expectedDep0, uint256 expectedDep1, uint256 fee0_previewMint, uint256 fee1_previewMint) =
            almInfo.previewMint(vid, sharesAmount);

        (uint256 expectedMintShares, uint256 fee0_previewDep, uint256 fee1_previewDep) =
            almInfo.previewDeposit(vid, expectedDep0, expectedDep1);

        assertEq(fee0_previewMint, fee0_previewDep, "Fee0 mismatch");
        assertEq(fee1_previewMint, fee1_previewDep, "Fee1 mismatch");
        assertEq(sharesAmount, expectedMintShares, "Shares mismatch");

        assertTrue(expectedDep0 <= preBal0, "Token0 balance too low");
        assertTrue(expectedDep1 <= preBal1, "Token1 balance too low");

        vm.prank(user);
        MintProceeds memory proceeds = almUser.deposit(vid, expectedDep0, expectedDep1, user);
        (uint256 postBal0, uint256 postBal1) = _bal(user);

        assertEq(postBal0, preBal0 - expectedDep0, "Token0 balance post-deposit mismatch");
        assertEq(postBal1, preBal1 - expectedDep1, "Token1 balance post-deposit mismatch");
        assertEq(proceeds.spent0, expectedDep0, "Spent0 mismatch");
        assertEq(proceeds.spent1, expectedDep1, "Spent1 mismatch");
        assertEq(_getUserShares(), preShares + proceeds.shares, "User shares post-deposit mismatch");
        assertEq(proceeds.shares, expectedMintShares, "Minted shares vs expected mismatch");
    }

    function testVaultLifecycle() internal virtual {
        createVault();
        (uint256 minP, uint256 maxP) = narrowRange();
        openV3Ranges(minP, maxP);
        verifyRanges();
        testDualTokenDeposit();
        testSingleSidedDeposits();
        testDualTokenWithdrawal();
        testSingleSidedWithdrawals();
    }

    function testCompleteALMLifecycle() public virtual { testVaultLifecycle(); }

    function testDualTokenDeposit() internal {
        (uint256 preBal0, uint256 preBal1) = _bal(user);
        uint256 preShares = _shares();
        (uint256 amt0, uint256 amt1) = _depositAmts();
        _reqGt0(amt0, "Amt0 must be >0 for dual deposit");
        _reqGt0(amt1, "Amt1 must be >0 for dual deposit");

        (uint256 expectedShares,,) = almInfo.previewDeposit(vid, amt0, amt1);
        _reqGt0(expectedShares, "Expected shares must be >0");

        vm.prank(user);
        MintProceeds memory proceeds = almUser.deposit(vid, amt0, amt1, user);

        assertEq(proceeds.shares, expectedShares, "Shares mismatch");
        assertEq(_shares(), preShares + expectedShares, "User shares increase mismatch");
        assertEq(IERC20(t0).balanceOf(user), preBal0 - amt0, "Token0 balance decrease mismatch");
        assertEq(IERC20(t1).balanceOf(user), preBal1 - amt1, "Token1 balance decrease mismatch");
    }

    function testSingleSidedDeposits() internal {
        testSingleSidedDepositToken0();
        testSingleSidedDepositToken1();
    }

    function testSingleSidedDepositToken0() internal {
        (uint256 amt0,) = _depositAmts();
        _reqGt0(amt0, "Amt0 must be >0 for single deposit");
        (uint256 preBal0, uint256 preBal1) = _bal(user);
        uint256 preShares = _shares();

        (uint256 expectedShares,,) = almInfo.previewDeposit(vid, amt0, 0);
        _reqGt0(expectedShares, "Expected shares (T0) must be >0");

        vm.prank(user);
        MintProceeds memory proceeds = almUser.deposit(vid, amt0, 0, user);

        assertEq(proceeds.shares, expectedShares, "Shares (T0) mismatch");
        assertEq(_shares(), preShares + expectedShares, "User shares (T0) increase mismatch");
        assertEq(IERC20(t0).balanceOf(user), preBal0 - amt0, "Token0 bal (T0) decrease mismatch");
        assertEq(IERC20(t1).balanceOf(user), preBal1, "Token1 bal (T0) unchanged mismatch");
    }

    function testSingleSidedDepositToken1() internal {
        uint256 amt1 = _depositAmount1Wei();
        _requirePositive(amt1, "Amt1 must be >0 for single deposit");

        (uint256 preBal0, uint256 preBal1) = _bal(user);
        uint256 preShares = _shares();

        (uint256 expectedShares, uint256 fee0, uint256 fee1) = almInfo.previewDeposit(vid, 0, amt1);
        _requirePositive(expectedShares, "Expected shares (T1) must be >0");

        vm.prank(user);
        MintProceeds memory proceeds = almUser.deposit(vid, 0, amt1, user);

        assertEq(proceeds.shares, expectedShares, "Shares (T1) mismatch");
        assertEq(_shares(), preShares + expectedShares, "User shares (T1) increase mismatch");
        assertEq(IERC20(t0).balanceOf(user), preBal0, "Token0 bal (T1) unchanged mismatch");
        assertEq(IERC20(t1).balanceOf(user), preBal1 - amt1, "Token1 bal (T1) decrease mismatch");
    }

    function testDualTokenWithdrawal() internal {
        uint256 currentShares = _shares();
        _requirePositive(currentShares, "User must have shares for withdrawal");

        uint256 sharesToWithdraw = currentShares / 2;
        _requirePositive(sharesToWithdraw, "Shares to withdraw must be >0");
        (uint256 preBal0, uint256 preBal1) = _bal(user);

        (uint256 expectedRec0, uint256 expectedRec1, uint256 fee0, uint256 fee1) =
            almInfo.previewWithdraw(vid, sharesToWithdraw, user);
        _requirePositive(expectedRec0 + expectedRec1, "Expected recovered total must be >0");

        vm.prank(user);
        BurnProceeds memory proceeds = almUser.redeem(vid, sharesToWithdraw, user);

        assertEq(proceeds.recovered0, expectedRec0, "Recovered T0 mismatch");
        assertEq(proceeds.recovered1, expectedRec1, "Recovered T1 mismatch");
        assertEq(_shares(), currentShares - sharesToWithdraw, "User shares decrease mismatch");
        assertEq(IERC20(t0).balanceOf(user), preBal0 + proceeds.recovered0, "Token0 bal increase mismatch");
        assertEq(IERC20(t1).balanceOf(user), preBal1 + proceeds.recovered1, "Token1 bal increase mismatch");
    }

    function testSingleSidedWithdrawals() internal {
        testSingleSidedWithdrawalToken0();
        testSingleSidedWithdrawalToken1();
    }

    function testSingleSidedWithdrawalToken0() internal {
        uint256 currentShares = _shares();
        _requirePositive(currentShares, "User must have shares for single T0 withdrawal");

        uint256 sharesToWithdraw = currentShares / 4;
        _requirePositive(sharesToWithdraw, "Shares to withdraw (single T0) must be >0");
        (uint256 preBal0, ) = _bal(user);

        vm.prank(user);
        BurnProceeds memory proceeds = almUser.withdrawSingle0(vid, sharesToWithdraw, user);
        _requirePositive(proceeds.recovered0, "Recovered T0 (single) must be >0");

        assertTrue(IERC20(t0).balanceOf(user) > preBal0, "Token0 bal (single T0) should increase");
        assertEq(_shares(), currentShares - sharesToWithdraw, "User shares (single T0) decrease mismatch");
    }

    function testSingleSidedWithdrawalToken1() internal {
        uint256 currentShares = _shares();
        _requirePositive(currentShares, "User must have shares for single T1 withdrawal");

        uint256 sharesToWithdraw = currentShares / 4;
         _requirePositive(sharesToWithdraw, "Shares to withdraw (single T1) must be >0");
        (, uint256 preBal1) = _bal(user);

        vm.prank(user);
        BurnProceeds memory proceeds = almUser.withdrawSingle1(vid, sharesToWithdraw, user);
        _requirePositive(proceeds.recovered1, "Recovered T1 (single) must be >0");

        assertTrue(IERC20(t1).balanceOf(user) > preBal1, "Token1 bal (single T1) should increase");
        assertEq(_shares(), currentShares - sharesToWithdraw, "User shares (single T1) decrease mismatch");
    }

    function testRebalanceWithSwaps() public virtual {
        createVault();
        _setupInitialRebalance();
        _performSwapRebalance();
        _verifySwapResults();
    }

    function _setupInitialRebalance() internal {
        (address tok0, address tok1) = _getTokens();
        (uint256 narrowMinP, uint256 narrowMaxP) = narrowRange();
        uint16[] memory initWeights = weights();
        bytes32[] memory initPids = _poolIds();
        require(initPids.length > 0 && initPids.length == initWeights.length, "Invalid initial pool/weight setup");

        RangeParams[] memory initRanges = new RangeParams[](initPids.length);
        PoolInfo memory pInfo;

        for (uint256 i = 0; i < initPids.length; i++) {
             pInfo = almInfo.poolInfo(initPids[i]);
             _requireNonZero(uint256(uint16(pInfo.tickSize)), "Tick size not set for initial range setup");
            (int24 lowerTick, int24 upperTick) = DM.priceX96RangeToTicks(
                DM.priceToPriceX96(narrowMinP), DM.priceToPriceX96(narrowMaxP), int24(pInfo.tickSize), pInfo.inverted
            );
            initRanges[i] = RangeParams({
                poolId: initPids[i],
                lowerPriceX96: DM.tickToPriceX96V3(lowerTick),
                upperPriceX96: DM.tickToPriceX96V3(upperTick),
                liquidity: 0,
                weightBp: initWeights[i]
            });
        }

        RebalanceParams memory initRebal = RebalanceParams({
            ranges: initRanges, swapInputs: new address[](0),
            swapRouters: new address[](0), swapData: new bytes[](0)
        });
        vm.prank(keeper);
        almProtected.rebalance(vid, initRebal);
        verifyRanges();
    }

    // Storage variables to track swap state
    uint256 private _cash0BeforeSwap;
    uint256 private _cash1BeforeSwap;

    function _performSwapRebalance() internal {
        (address tok0, address tok1) = _getTokens();
        uint256 excessT0Amt = 100 * (10 ** d0);
        deal(tok0, diamond, IERC20(tok0).balanceOf(diamond) + excessT0Amt);

        (_cash0BeforeSwap, _cash1BeforeSwap) = _cash();
        _requirePositive(_cash0BeforeSwap, "Vault should have cash0 before swap");

        // Prepare target ranges
        RangeParams[] memory targetRanges = _prepareTargetRanges();

        // Prepare swap data
        uint256 amtToSwap = _cash0BeforeSwap / 2;
        _requirePositive(amtToSwap, "Amount to swap must be >0");

        (address swapRouter,,,bytes memory swapCallData) = BTRSwapUtils.generateSwapData(tok0, tok1, amtToSwap);

        address[] memory swapIns = new address[](1);
        swapIns[0] = tok0;
        address[] memory swapRouters = new address[](1);
        swapRouters[0] = swapRouter;
        bytes[] memory swapDataArr = new bytes[](1);
        swapDataArr[0] = swapCallData;

        RebalanceParams memory rebalWithSwap = RebalanceParams({
            ranges: targetRanges, swapInputs: swapIns,
            swapRouters: swapRouters, swapData: swapDataArr
        });

        vm.prank(keeper);
        almProtected.rebalance(vid, rebalWithSwap);
    }

    function _prepareTargetRanges() internal view returns (RangeParams[] memory targetRanges) {
        (uint256 wideMinP, uint256 wideMaxP) = wideRange();
        uint16[] memory initWeights = weights();
        bytes32[] memory initPids = _poolIds();

        targetRanges = new RangeParams[](initPids.length);

        for (uint256 i = 0; i < initPids.length; i++) {
            PoolInfo memory pInfo = almInfo.poolInfo(initPids[i]);
            _requireNonZero(uint256(uint16(pInfo.tickSize)), "Tick size not set for target range setup");
            (int24 wideLowerTick, int24 wideUpperTick) = DM.priceX96RangeToTicks(
                DM.priceToPriceX96(wideMinP), DM.priceToPriceX96(wideMaxP), int24(pInfo.tickSize), pInfo.inverted
            );
            targetRanges[i] = RangeParams({
                poolId: initPids[i],
                lowerPriceX96: DM.tickToPriceX96V3(wideLowerTick),
                upperPriceX96: DM.tickToPriceX96V3(wideUpperTick),
                liquidity: 0,
                weightBp: initWeights[i]
            });
        }
    }

    function _verifySwapResults() internal {
        (uint256 cash0After, uint256 cash1After) = _cash();

        // Verify swap worked correctly
        assertTrue(cash0After < _cash0BeforeSwap, "Cash0 should decrease post-swap");
        assertTrue(cash1After > _cash1BeforeSwap, "Cash1 should increase post-swap");

        bytes32[] memory ridsAfter = almInfo.vaultRangeIds(vid);
        _requirePositive(ridsAfter.length, "No ranges post-rebalance");
        Range memory rangeDataAfter = almInfo.range(ridsAfter[0]);
        _requirePositive(rangeDataAfter.liquidity, "New range should have liquidity");

        bytes32[] memory initPids = _poolIds();
        if (initPids.length == 1) {
            (uint256 wideMinP, uint256 wideMaxP) = wideRange();
            PoolInfo memory pInfo = almInfo.poolInfo(initPids[0]);
             _requireNonZero(uint256(uint16(pInfo.tickSize)), "Tick size not set for assertion pInfo");
            (int24 expectedLowerTick, int24 expectedUpperTick) = DM.priceX96RangeToTicks(
                DM.priceToPriceX96(wideMinP), DM.priceToPriceX96(wideMaxP), int24(pInfo.tickSize), pInfo.inverted
            );

            Range memory actualRange = almInfo.range(ridsAfter[0]);

            assertEq(actualRange.lowerTick, expectedLowerTick, "Lower tick mismatch post-rebalance");
            assertEq(actualRange.upperTick, expectedUpperTick, "Upper tick mismatch post-rebalance");
        }
    }
}
