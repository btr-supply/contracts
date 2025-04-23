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
 * @title BNB ALM Test - Integration tests for ALM on BNB Chain context
 * @copyright 2025
 * @notice Verifies ALM functionality using BNB Chain specific pools/adapters (e.g., PancakeSwap)
 * @dev Inherits from ALMBaseTest
 * @author BTR Team
 */

import {ALMBaseTest} from "../integration/ALMBaseTest.sol";
import {BNBChainMeta} from "./ChainMeta.sol";
import {Test, console} from "forge-std/Test.sol";
import {DEX, PoolInfo} from "@/BTRTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ALMVault, Range, Rebalance, VaultInitParams} from "@/BTRTypes.sol";
import {BTRUtils} from "@libraries/BTRUtils.sol";

/**
 * @title BNBALMTest
 * @notice Base integration test for ALM on BNB Chain
 * @dev Abstract base class combining ALM test functionality with BNB Chain setup
 */
abstract contract BNBALMTest is ALMBaseTest, BNBChainMeta {
    using BTRUtils for bytes32;

    // BNB-specific price range constants
    uint256 constant STABLE_LOWER_PRICE = 0.995e18; // $0.995 (token0/token1)
    uint256 constant STABLE_UPPER_PRICE = 1.005e18; // $1.005 (token0/token1)

    // Initial amount constants
    uint256 public constant BASE_INITIAL_AMOUNT = 1e6; // 1,000,000 tokens
    uint256 public constant BASE_DEPOSIT_AMOUNT = 1000; // 1,000 tokens

    function setUp() public virtual override {
        // Call parent setup to deploy diamond and initialize facets
        super.setUp();

        // Fork BNB Chain
        vm.createSelectFork(RPC_URL);

        // Setup default token balances for user
        setupDefaultTokenBalances(user);

        // Setup DEX adapter and pool
        _setupDEXAdapter();
        _setupDEXPool();
    }

    /**
     * @notice Setup default token balances for testing
     */
    function setupDefaultTokenBalances(address userAddress) internal {
        (uint256 token0Unit, uint256 token1Unit) = getTokenWeiPerUnit();
        uint256 initialAmount0 = BASE_INITIAL_AMOUNT * token0Unit;
        uint256 initialAmount1 = BASE_INITIAL_AMOUNT * token1Unit;

        // Fund the treasury and user with tokens
        deal(USDT, treasury, initialAmount0);
        deal(USDT, userAddress, initialAmount0);
        deal(USDC, treasury, initialAmount1);
        deal(USDC, userAddress, initialAmount1);

        // Approve tokens for treasury
        vm.startPrank(treasury);
        IERC20(USDT).approve(address(diamond), type(uint256).max);
        IERC20(USDC).approve(address(diamond), type(uint256).max);
        vm.stopPrank();

        // Approve tokens for user
        vm.startPrank(userAddress);
        IERC20(USDT).approve(address(diamond), type(uint256).max);
        IERC20(USDC).approve(address(diamond), type(uint256).max);
        vm.stopPrank();
    }

    // Implement the abstract functions from ALMBaseTest

    function getToken0() internal view override returns (address) {
        return USDT;
    }

    function getToken1() internal view override returns (address) {
        return USDC;
    }

    function getTestStablePool() internal view virtual override returns (address) {
        return THENAV3_USDT_USDC_POOL; // Default to Thena as test pool
    }

    function getTestPoolId() internal view virtual override returns (bytes32) {
        return bytes32(uint256(uint160(getTestStablePool())));
    }

    function getTestAdapter() internal view virtual override returns (address) {
        // Will be implemented by specific DEX tests
        return address(0);
    }

    function getTestDEX() internal view virtual override returns (DEX) {
        return DEX.THENA; // Default to Thena
    }

    function getTokenDecimals() internal view override returns (uint8, uint8) {
        return (IERC20Metadata(getToken0()).decimals(), IERC20Metadata(getToken1()).decimals());
    }

    function getTokenWeiPerUnit() internal view override returns (uint256, uint256) {
        (uint8 token0Decimals, uint8 token1Decimals) = getTokenDecimals();
        return (10 ** token0Decimals, 10 ** token1Decimals);
    }

    function getDepositAmount() internal view override returns (uint256) {
        (uint256 token0Unit,) = getTokenWeiPerUnit();
        return BASE_DEPOSIT_AMOUNT * token0Unit;
    }

    /**
     * @notice Create a basic single-range deployment with stable or default range
     * @param useSteadyRange Whether to use the narrower stablecoin range
     */
    function createBasicRange(bool useSteadyRange) internal {
        if (useSteadyRange) {
            createBasicRange(STABLE_LOWER_PRICE, STABLE_UPPER_PRICE);
        } else {
            createBasicRange();
        }
    }

    /**
     * @notice Run a standard lifecycle test for any DEX
     */
    function runLifecycleTest(bool useStableRange) internal {
        // Create a vault
        vaultId = createVault();

        // Create initial range
        createBasicRange(useStableRange);

        // Deposit into the vault
        uint256 depositAmount = getDepositAmount();
        depositToVault(vaultId, depositAmount, depositAmount);

        // Rebalance with the same range to test position reuse without swaps
        createBasicRange(useStableRange);

        // Verify ranges
        verifyRanges("BNB ALM Test");

        // Withdraw all shares
        withdrawAllShares(vaultId);
    }

    /**
     * @notice Run a standard fee collection test
     */
    function runFeeCollectionTest(bool useStableRange) internal {
        // Create a vault
        vaultId = createVault();

        // Create initial range
        createBasicRange(useStableRange);

        // Deposit into the vault
        uint256 depositAmount = getDepositAmount();
        depositToVault(vaultId, depositAmount, depositAmount);

        // Simulate fee accumulation
        simulateFeeAccumulation();

        // Collect fees
        collectFees();

        // Withdraw all shares
        withdrawAllShares(vaultId);
    }
}
