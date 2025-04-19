// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BNBALMTest} from "./BNBALMTest.t.sol";
import {DEX, Range, Rebalance, VaultInitParams, PoolInfo} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";
import {ALMFacet} from "@facets/ALMFacet.sol";
import {UniV3AdapterFacet} from "@facets/adapters/dexs/UniV3AdapterFacet.sol";
import {DEXAdapterFacet} from "@facets/abstract/DEXAdapterFacet.sol";
import {BaseDiamondTest} from "../BaseDiamondTest.t.sol";
import {BNBChainMeta} from "./ChainMeta.sol";
import {IUniV3Pool} from "@interfaces/dexs/IUniV3Pool.sol";
import {LibDEXMaths} from "@libraries/LibDEXMaths.sol";
import {LibMaths} from "@libraries/LibMaths.sol";

/**
 * @title UniV3StableALMTest
 * @notice Test for UniV3 stablecoin pools that demonstrates:
 * - DEX adapter adding
 * - Pool info registration
 * - Price to tick conversion
 * - Vault initialization and deposits
 * - Liquidity amount calculations
 * - Using abstract DexAdapterFacet for DEX operations
 */
contract UniV3StableALMTest is BaseDiamondTest, BNBChainMeta {
    using SafeERC20 for IERC20;
    using BTRUtils for uint32;
    using BTRUtils for bytes32;

    // Test constants for price range
    uint256 constant DEFAULT_LOWER_PRICE = 0.995e18; // $0.995
    uint256 constant DEFAULT_UPPER_PRICE = 1.005e18; // $1.005

    // Facets
    ALMFacet public almFacet;
    DEXAdapterFacet public dexAdapterFacet;

    // Test state
    uint32 public vaultId;
    address public user;
    address public uniV3Adapter;

    function getToken0() internal pure returns (address) {
        return USDT;
    }

    function getToken1() internal pure returns (address) {
        return USDC;
    }

    function getTokenDecimals() internal view returns (uint8, uint8) {
        return (
            18, // USDT is 18 decimals in tests
            18 // USDC is 18 decimals in tests
        );
    }

    function getTokenWeiPerUnit() internal view returns (uint256, uint256) {
        (uint8 token0Decimals, uint8 token1Decimals) = getTokenDecimals();
        return (10 ** token0Decimals, 10 ** token1Decimals);
    }

    function getDepositAmount() internal view returns (uint256) {
        (uint256 token0Unit,) = getTokenWeiPerUnit();
        return 1000 * token0Unit; // 1,000 tokens
    }

    function setUp() public override {
        console.log("Setting up UniV3StableALMTest");

        // Deploy basic infrastructure without forking BNB chain
        // This allows the test to be run in environments where the fork is not available

        // Call BaseDiamondTest setup which creates the diamond and necessary infrastructure
        BaseDiamondTest.setUp();

        // Initialize interfaces needed for testing
        almFacet = ALMFacet(address(diamond));
        dexAdapterFacet = DEXAdapterFacet(address(diamond));

        // Setup default user for testing
        user = makeAddr("user");

        // Deploy the UniV3 adapter
        vm.startPrank(admin);
        uniV3Adapter = address(new UniV3AdapterFacet());
        console.log("UniV3 adapter deployed at:", uniV3Adapter);
        vm.stopPrank();
    }

    function testVaultLifecycle() public {
        console.log("===== Testing UniV3 stable vault functionality =====");

        // Try to fork BNB chain - skip if not available
        uint256 forkId;
        try vm.createSelectFork(RPC_URL) returns (uint256 _forkId) {
            forkId = _forkId;
            console.log("Successfully forked BNB Chain");
        } catch {
            console.log("Skipping test: Unable to fork BNB Chain");
            return;
        }

        // Setup environment now that we have a fork
        console.log("Setting up test environment");

        // Setup DEX adapter
        vm.startPrank(admin);
        almFacet.updateDexAdapter(DEX.UNISWAP, uniV3Adapter);
        console.log("UniV3 adapter registered");

        // Setup tokens for testing
        (uint256 token0Unit, uint256 token1Unit) = getTokenWeiPerUnit();
        uint256 initialAmount = 1e6 * token0Unit;

        // Deal tokens to treasury and user
        deal(getToken0(), treasury, initialAmount);
        deal(getToken0(), user, initialAmount);
        deal(getToken1(), treasury, initialAmount);
        deal(getToken1(), user, initialAmount);

        // Approve tokens
        vm.startPrank(treasury);
        IERC20(getToken0()).approve(address(diamond), type(uint256).max);
        IERC20(getToken1()).approve(address(diamond), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user);
        IERC20(getToken0()).approve(address(diamond), type(uint256).max);
        IERC20(getToken1()).approve(address(diamond), type(uint256).max);
        vm.stopPrank();

        // Register pool
        bytes32 poolId = getTestPoolId();
        int24 tickSpacing = getPoolTickSpacing(getTestStablePool());
        uint24 fee = getPoolFee(getTestStablePool());

        registerPool(poolId, DEX.UNISWAP, getToken0(), getToken1(), uint32(uint24(tickSpacing)), fee);
        vm.stopPrank();

        console.log("Pool registered successfully");

        // Continue with test implementation
        uint256 TEST_LOWER_PRICE = 0.995e18; // $0.995
        uint256 TEST_UPPER_PRICE = 1.005e18; // $1.005

        // Step 1: Create a vault
        vaultId = createVault();
        console.log("Created vault with ID:", vaultId);

        // Step 2: Get pool information
        address token0 = getToken0();
        address token1 = getToken1();
        console.log("Token0:", token0);
        console.log("Token1:", token1);

        // Step 3: Calculate price ticks using LibDEXMaths
        console.log("Price range conversion:");
        console.log("Lower price:", TEST_LOWER_PRICE);
        console.log("Upper price:", TEST_UPPER_PRICE);

        // Calculate ticks from prices
        (int24 lowerTick, int24 upperTick) = getPriceTicks(getTestStablePool(), TEST_LOWER_PRICE, TEST_UPPER_PRICE);

        console.log("Converted to ticks - Lower:");
        console.log(lowerTick);
        console.log("Upper:");
        console.log(upperTick);

        // Step 4: Create a range for the vault using ticks
        Range[] memory ranges = new Range[](1);
        ranges[0] = Range({
            id: bytes32(0),
            positionId: bytes32(0),
            vaultId: vaultId,
            poolId: getTestPoolId(),
            weightBps: 10000, // 100% weight
            liquidity: 0,
            lowerTick: lowerTick,
            upperTick: upperTick
        });

        // Create a rebalance request to initialize the range
        Rebalance memory rebalanceData = Rebalance({
            ranges: ranges,
            swapInputs: new address[](0),
            swapRouters: new address[](0),
            swapData: new bytes[](0)
        });

        // Execute rebalance to create the position using DexAdapterFacet
        vm.startPrank(manager);
        almFacet.rebalance(vaultId, rebalanceData);
        vm.stopPrank();
        console.log("Range created via abstract DexAdapterFacet");

        // Step 5: Deposit tokens into the vault
        uint256 depositAmount = getDepositAmount();
        console.log("Depositing amount:", depositAmount);

        deal(getToken0(), user, depositAmount);
        deal(getToken1(), user, depositAmount);

        vm.startPrank(user);
        IERC20(getToken0()).approve(address(diamond), depositAmount);
        IERC20(getToken1()).approve(address(diamond), depositAmount);
        vm.stopPrank();

        uint256 shares = depositToVault(vaultId, depositAmount, depositAmount);
        console.log("Received shares:", shares);

        // Verify the ranges were set correctly
        verifyRanges("UniV3 specific tick range");

        // Step 6: Test liquidity <-> amounts conversion using DexAdapterFacet
        bytes32[] memory rangeIds = getVaultRangeIds(vaultId);
        require(rangeIds.length > 0, "No ranges found");

        // Get position info using the abstract DexAdapterFacet
        vm.startPrank(user);
        (uint128 liquidity,,,,) = dexAdapterFacet.getPositionInfo(rangeIds[0]);
        console.log("Position liquidity:", liquidity);

        // Test getAmountsForLiquidity - converting liquidity to token amounts
        (uint256 amount0, uint256 amount1) = dexAdapterFacet.getAmountsForLiquidity(rangeIds[0], liquidity);
        console.log("Amounts for liquidity:");
        console.log("Token0 amount:", amount0);
        console.log("Token1 amount:", amount1);

        // Test getLiquidityForAmounts - converting token amounts to liquidity
        uint128 newLiquidity = dexAdapterFacet.getLiquidityForAmounts(rangeIds[0], amount0, amount1);
        console.log("Liquidity for amounts:", newLiquidity);
        vm.stopPrank();

        // Step 7: Withdraw all shares from the vault
        (uint256 withdrawn0, uint256 withdrawn1) = withdrawAllShares(vaultId);
        console.log("Tokens withdrawn:");
        console.log("Token0 withdrawn:", withdrawn0);
        console.log("Token1 withdrawn:", withdrawn1);

        console.log("===== Test completed successfully =====");
    }

    function getTestStablePool() internal pure returns (address) {
        return UNIV3_USDT_USDC_POOL;
    }

    function getTestPoolId() internal pure returns (bytes32) {
        return BTRUtils.toBytes32(UNIV3_USDT_USDC_POOL);
    }

    function getTestAdapter() internal view returns (address) {
        return uniV3Adapter;
    }

    function getTestDEX() internal pure returns (DEX) {
        return DEX.UNISWAP;
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
     * @notice Register a pool in the protocol
     */
    function registerPool(bytes32 poolId, DEX dex, address token0, address token1, uint32 tickSpacing, uint24 fee)
        internal
    {
        vm.startPrank(admin);
        PoolInfo memory poolInfo = PoolInfo({
            poolId: poolId,
            dex: dex,
            token0: token0,
            token1: token1,
            tickSize: tickSpacing,
            fee: uint32(fee)
        });

        (bool success,) = address(diamond).call(
            abi.encodeWithSignature(
                "setPoolInfo(bytes32,((bytes32,uint8,address,address,uint32,uint32)))", poolId, poolInfo
            )
        );

        require(success, "Pool registration failed");
        vm.stopPrank();
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
     * @notice Get range IDs for a vault
     */
    function getVaultRangeIds(uint32 _vaultId) internal view returns (bytes32[] memory) {
        return _vaultId.getVault().ranges;
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
     * @notice Withdraw all shares from a vault
     */
    function withdrawAllShares(uint32 _vaultId) internal returns (uint256 amount0, uint256 amount1) {
        vm.startPrank(user);
        uint256 shares = almFacet.balanceOf(_vaultId, user);
        (amount0, amount1,,) = almFacet.withdraw(_vaultId, shares, user);
        vm.stopPrank();
        return (amount0, amount1);
    }

    /**
     * @notice Verify ranges are set correctly
     */
    function verifyRanges(string memory label) internal virtual {
        bytes32[] memory rangeIds = getVaultRangeIds(vaultId);
        require(rangeIds.length > 0, string(abi.encodePacked("No ranges found for ", label)));

        for (uint256 i = 0; i < rangeIds.length; i++) {
            (uint128 liquidity,,,,) = dexAdapterFacet.getPositionInfo(rangeIds[i]);
            require(liquidity > 0, string(abi.encodePacked("Range ", i, " has no liquidity")));
        }
    }

    /**
     * @notice Convert prices to ticks
     */
    function getPriceTicks(address pool, uint256 lowerPrice, uint256 upperPrice)
        internal
        view
        returns (int24 lowerTick, int24 upperTick)
    {
        // Get the current sqrt price
        (uint160 sqrtPriceX96, int24 currentTick,,,,,) = IUniV3Pool(pool).slot0();

        // Calculate ticks from price values
        int24 tickSpacing = IUniV3Pool(pool).tickSpacing();

        // Convert prices to ticks
        int24 rawLowerTick =
            LibDEXMaths.getTickAtSqrtPrice(uint160(LibMaths.sqrt(uint256(1e18) * LibDEXMaths.Q96 / lowerPrice)));
        int24 rawUpperTick =
            LibDEXMaths.getTickAtSqrtPrice(uint160(LibMaths.sqrt(uint256(1e18) * LibDEXMaths.Q96 / upperPrice)));

        // Round to valid tick spacing
        lowerTick = LibDEXMaths.roundToTickSpacing(rawLowerTick, tickSpacing, false);
        upperTick = LibDEXMaths.roundToTickSpacing(rawUpperTick, tickSpacing, true);

        return (lowerTick, upperTick);
    }
}
