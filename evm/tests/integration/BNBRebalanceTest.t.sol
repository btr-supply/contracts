// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {BNBALMTest} from "./BNBALMTest.t.sol";
import "forge-std/console.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {ALMVault, Range, Rebalance, DEX} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {ThenaV3AdapterFacet} from "@facets/adapters/dexs/ThenaV3AdapterFacet.sol";
import {UniV3AdapterFacet} from "@facets/adapters/dexs/UniV3AdapterFacet.sol";

/**
 * @title BNBRebalanceTest
 * @notice Test rebalancing between different DEXs on BNB Chain
 */
contract BNBRebalanceTest is BNBALMTest {
    using SafeERC20 for IERC20;

    // DEX adapters
    address public thenaAdapter;
    address public uniV3Adapter;

    // Default price constants
    uint256 constant DEFAULT_LOWER_PRICE = 0.99e18;
    uint256 constant DEFAULT_UPPER_PRICE = 1.01e18;

    // Mock swap data - in a real test these would be actual calldata for routers
    bytes public constant SWAP_TOKEN0_TO_TOKEN1 = hex"00";
    bytes public constant SWAP_TOKEN1_TO_TOKEN0 = hex"01";

    function setUp() public override {
        // Deploy adapters before setup
        thenaAdapter = address(new ThenaV3AdapterFacet());
        uniV3Adapter = address(new UniV3AdapterFacet());

        // Call parent setup
        super.setUp();

        // Register DEX adapters
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.THENA, thenaAdapter);
        almFacet.updateDexAdapter(DEX.UNISWAP, uniV3Adapter);
        vm.stopPrank();
    }

    /**
     * @notice Test rebalancing between DEXs
     */
    function testRebalancing() public {
        // Create a vault
        vaultId = createVault();

        // Start with 100% Thena
        createSingleDEXRange(DEX.THENA);

        // Deposit into the vault
        uint256 depositAmount = getDepositAmount();
        depositToVault(vaultId, depositAmount, depositAmount);

        // Verify ranges
        verifyRanges("Initial Thena Range");

        // Rebalance to multiple DEXs
        rebalanceToMultiDEX();

        // Verify new range distribution
        verifyRanges("Multi-DEX Ranges");

        // Withdraw all shares
        withdrawAllShares(vaultId);
    }

    /**
     * @notice Create a range on a single DEX with 100% allocation
     */
    function createSingleDEXRange(DEX dex) internal {
        address poolAddress;
        if (dex == DEX.THENA) {
            poolAddress = THENAV3_USDT_USDC_POOL;
        } else if (dex == DEX.UNISWAP) {
            poolAddress = UNIV3_USDT_USDC_POOL;
        } else {
            revert("Unsupported DEX");
        }

        // Get ticks for the pool
        (int24 lowerTick, int24 upperTick) = getPriceTicks(poolAddress, DEFAULT_LOWER_PRICE, DEFAULT_UPPER_PRICE);

        Range[] memory ranges = new Range[](1);

        // Create single range with 100% weight
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(poolAddress),
            weightBps: 10000, // 100%
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
     * @notice Rebalance from single DEX to multiple DEXs
     */
    function rebalanceToMultiDEX() internal {
        // Get ticks for each pool
        (int24 thenaLowerTick, int24 thenaUpperTick) =
            getPriceTicks(THENAV3_USDT_USDC_POOL, DEFAULT_LOWER_PRICE, DEFAULT_UPPER_PRICE);
        (int24 uniV3LowerTick, int24 uniV3UpperTick) =
            getPriceTicks(UNIV3_USDT_USDC_POOL, DEFAULT_LOWER_PRICE, DEFAULT_UPPER_PRICE);

        Range[] memory ranges = new Range[](2);

        // Thena range (40%)
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(THENAV3_USDT_USDC_POOL),
            weightBps: 4000, // 40%
            liquidity: 0,
            lowerTick: thenaLowerTick,
            upperTick: thenaUpperTick
        });

        // UniV3 range (60%)
        ranges[1] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(UNIV3_USDT_USDC_POOL),
            weightBps: 6000, // 60%
            liquidity: 0,
            lowerTick: uniV3LowerTick,
            upperTick: uniV3UpperTick
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
     * @notice Override getTestAdapter to use Thena as default
     */
    function getTestAdapter() internal view override returns (address) {
        return thenaAdapter;
    }

    /**
     * @notice Simulate a token imbalance in the vault
     * @param amount0 Amount of token0 to add
     * @param amount1 Amount of token1 to add
     */
    function simulateImbalance(uint256 amount0, uint256 amount1) internal {
        if (amount0 > 0) {
            deal(getToken0(), treasury, amount0);
            vm.startPrank(treasury);
            IERC20(getToken0()).transfer(address(diamond), amount0);
            vm.stopPrank();
        }

        if (amount1 > 0) {
            deal(getToken1(), treasury, amount1);
            vm.startPrank(treasury);
            IERC20(getToken1()).transfer(address(diamond), amount1);
            vm.stopPrank();
        }

        console.log("Simulated imbalance: added %d token0, %d token1", amount0, amount1);
    }

    /**
     * @notice Rebalance with a token swap to correct imbalance
     * @param swapExcessToken0 True to swap token0 to token1, false for token1 to token0
     */
    function rebalanceWithSwap(bool swapExcessToken0) internal {
        // Get token units
        (uint256 token0Unit, uint256 token1Unit) = getTokenWeiPerUnit();

        // Get ticks for the test pool
        (int24 lowerTick, int24 upperTick) =
            getPriceTicks(getTestStablePool(), DEFAULT_LOWER_PRICE, DEFAULT_UPPER_PRICE);

        Range[] memory ranges = new Range[](1);

        // Reuse the same range
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: getTestPoolId(),
            weightBps: 10000,
            liquidity: 0,
            lowerTick: lowerTick,
            upperTick: upperTick
        });

        // Setup swap
        address[] memory swapInputs = new address[](1);
        address[] memory swapRouters = new address[](1);
        bytes[] memory swapData = new bytes[](1);

        if (swapExcessToken0) {
            // Swap excess token0 to token1
            swapInputs[0] = getToken0();
            swapRouters[0] = CAKE_ROUTER;
            swapData[0] = SWAP_TOKEN0_TO_TOKEN1;
            console.log("Setup rebalance to swap excess token0 to token1");
        } else {
            // Swap excess token1 to token0
            swapInputs[0] = getToken1();
            swapRouters[0] = CAKE_ROUTER;
            swapData[0] = SWAP_TOKEN1_TO_TOKEN0;
            console.log("Setup rebalance to swap excess token1 to token0");
        }

        Rebalance memory rebalanceData =
            Rebalance({ranges: ranges, swapInputs: swapInputs, swapRouters: swapRouters, swapData: swapData});

        vm.startPrank(manager);

        // Mock the swap functionality since we can't actually call the router in tests
        vm.mockCall(CAKE_ROUTER, abi.encodeWithSignature("swap(bytes)"), abi.encode(true));

        // Simulate swap result by adjusting token balances
        if (swapExcessToken0) {
            uint256 swapAmount = token0Unit * 50;
            uint256 receiveAmount = token1Unit * 49; // 1% slippage

            // Remove token0 and add token1 to simulate swap
            deal(getToken0(), address(diamond), IERC20(getToken0()).balanceOf(address(diamond)) - swapAmount);
            deal(getToken1(), address(diamond), IERC20(getToken1()).balanceOf(address(diamond)) + receiveAmount);
        } else {
            uint256 swapAmount = token1Unit * 50;
            uint256 receiveAmount = token0Unit * 49; // 1% slippage

            // Remove token1 and add token0 to simulate swap
            deal(getToken1(), address(diamond), IERC20(getToken1()).balanceOf(address(diamond)) - swapAmount);
            deal(getToken0(), address(diamond), IERC20(getToken0()).balanceOf(address(diamond)) + receiveAmount);
        }

        // Execute rebalance
        almFacet.rebalance(vaultId, rebalanceData);

        // Clear mock
        vm.clearMockedCalls();

        vm.stopPrank();
    }

    /**
     * @notice Rebalance to a new price range
     */
    function rebalanceToNewRange() internal {
        // Shift the price range up by 0.01
        uint256 newLowerPrice = DEFAULT_LOWER_PRICE + 0.01e18;
        uint256 newUpperPrice = DEFAULT_UPPER_PRICE + 0.01e18;

        // Get ticks for the new range
        (int24 lowerTick, int24 upperTick) = getPriceTicks(getTestStablePool(), newLowerPrice, newUpperPrice);

        Range[] memory ranges = new Range[](1);

        // Create new range with updated ticks
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: getTestPoolId(),
            weightBps: 10000, // 100%
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

        console.log("Rebalanced to new range: %d - %d", newLowerPrice, newUpperPrice);
    }

    /**
     * @notice Verify ranges are set correctly
     */
    function verifyRanges(string memory label) internal virtual override {
        console.log("--- %s ---", label);

        bytes32[] memory rangeIds = getVaultRangeIds(vaultId);
        require(rangeIds.length > 0, "No ranges found");

        uint256[] memory weights = almFacet.getWeights(vaultId);
        console.log("Vault has", rangeIds.length, "ranges");

        // Verify each range
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < rangeIds.length; i++) {
            bytes32 rangeId = rangeIds[i];
            // Use low-level call to get range info to get the poolId
            (bool success, bytes memory data) =
                address(diamond).call(abi.encodeWithSignature("getRange(bytes32)", rangeId));
            require(success, "Failed to get range info");
            Range memory range = abi.decode(data, (Range));
            bytes32 poolId = range.poolId;

            totalWeight += weights[i];

            // Get position info
            try dexAdapterFacet.getPositionInfo(rangeId) returns (
                uint128 liquidity, uint256 amount0, uint256 amount1, uint128 fees0, uint128 fees1
            ) {
                console.log("Range", i);
                console.log("Pool:", BTRUtils.toAddress(poolId));
                console.log("Weight (bps):", weights[i]);
                console.log("Liquidity:", liquidity);

                assertTrue(liquidity > 0, "Range should have liquidity");
            } catch Error(string memory reason) {
                console.log("Failed to get position info:", reason);
            }
        }

        assertTrue(totalWeight == 10000, "Total weight should be 100%");

        // Verify total balances
        (uint256 totalBalance0, uint256 totalBalance1) = almFacet.getTotalBalances(vaultId);
        console.log("Total balance0:", totalBalance0);
        console.log("Total balance1:", totalBalance1);
        assertTrue(totalBalance0 > 0 || totalBalance1 > 0, "Vault should have token balances");
    }
}
