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
 * @title BNB Multi-DEX Test - Integration tests for swapping across multiple DEXs on BNB
 * @copyright 2025
 * @notice Verifies the SwapperFacet's ability to route trades across different DEX adapters on BNB Chain
 * @dev Tests aggregation or multi-hop swap logic
 * @author BTR Team
 */

import {BNBALMTest} from "./BNBALMTest.t.sol";
import {ALMVault, Range, Rebalance, DEX} from "@/BTRTypes.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {ThenaV3AdapterFacet} from "@facets/adapters/dexs/ThenaV3AdapterFacet.sol";
import {UniV3AdapterFacet} from "@facets/adapters/dexs/UniV3AdapterFacet.sol";
import {CakeV3AdapterFacet} from "@facets/adapters/dexs/CakeV3AdapterFacet.sol";

/**
 * @title BNBMultiDEXTest
 * @notice Integration test for multi-DEX functionality on BNB Chain
 */
contract BNBMultiDEXTest is BNBALMTest {
    // DEX adapters
    address public thenaAdapter;
    address public uniV3Adapter;
    address public cakeAdapter;

    // Pool weight constants
    uint16 public constant WEIGHT_20BPS = 2000; // 20%
    uint16 public constant WEIGHT_30BPS = 3000; // 30%
    uint16 public constant WEIGHT_50BPS = 5000; // 50%

    function setUp() public override {
        // Deploy adapters before setup
        thenaAdapter = address(new ThenaV3AdapterFacet());
        uniV3Adapter = address(new UniV3AdapterFacet());
        cakeAdapter = address(new CakeV3AdapterFacet());

        // Call parent setup
        super.setUp();

        // Register all DEX adapters
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.THENA, thenaAdapter);
        almFacet.updateDexAdapter(DEX.UNISWAP, uniV3Adapter);
        almFacet.updateDexAdapter(DEX.PANCAKESWAP, cakeAdapter);
        vm.stopPrank();
    }

    /**
     * @notice Test multi-DEX integration with UniswapV3, PancakeSwap, and Thena
     */
    function testMultiDEXLifecycle() public {
        // Create test vault with default parameters
        vaultId = createVault();

        // Create multi-DEX ranges
        createMultiDEXRanges();

        // Deposit into the vault
        uint256 depositAmount = getDepositAmount();
        depositToVault(vaultId, depositAmount, depositAmount);

        // Verify ranges
        verifyRanges("BNB MultiDEX Test");

        // Withdraw shares
        withdrawAllShares(vaultId);
    }

    /**
     * @notice Create ranges across multiple DEXs
     */
    function createMultiDEXRanges() internal {
        // Get ticks for each pool
        (int24 thenaLowerTick, int24 thenaUpperTick) =
            getPriceTicks(THENAV3_USDT_USDC_POOL, STABLE_LOWER_PRICE, STABLE_UPPER_PRICE);
        (int24 uniLowerTick, int24 uniUpperTick) =
            getPriceTicks(UNIV3_USDT_USDC_POOL, STABLE_LOWER_PRICE, STABLE_UPPER_PRICE);
        (int24 cakeLowerTick, int24 cakeUpperTick) =
            getPriceTicks(CAKEV3_USDT_USDC_POOL, STABLE_LOWER_PRICE, STABLE_UPPER_PRICE);

        Range[] memory ranges = new Range[](3);

        // Thena range (20%)
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(THENAV3_USDT_USDC_POOL),
            weightBps: WEIGHT_20BPS,
            liquidity: 0,
            lowerTick: thenaLowerTick,
            upperTick: thenaUpperTick
        });

        // Uniswap V3 range (30%)
        ranges[1] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(UNIV3_USDT_USDC_POOL),
            weightBps: WEIGHT_30BPS,
            liquidity: 0,
            lowerTick: uniLowerTick,
            upperTick: uniUpperTick
        });

        // PancakeSwap range (50%)
        ranges[2] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: BTRUtils.toBytes32(CAKEV3_USDT_USDC_POOL),
            weightBps: WEIGHT_50BPS,
            liquidity: 0,
            lowerTick: cakeLowerTick,
            upperTick: cakeUpperTick
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
}
