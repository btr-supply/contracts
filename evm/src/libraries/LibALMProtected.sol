// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    ALMVault,
    PoolInfo,
    Range,
    RangeParams,
    DEX,
    Registry,
    ErrorType,
    CoreStorage,
    RebalanceParams,
    RebalancePrep,
    VaultInitParams,
    Restrictions,
    RebalanceProceeds,
    MintProceeds,
    BurnProceeds
} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibDEXUtils as DU} from "@libraries/LibDEXUtils.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibSwap as SW} from "@libraries/LibSwap.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDEXAdapter} from "../../interfaces/IDEXAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Protected Library - ALM privileged operations
 * @copyright 2025
 * @notice Contains internal functions for ALM privileged operations including vault creation, pool registration, range management, and vault upkeep operations
 * @dev Sub-facet for ALM privileged operations:
- Functions: `createVault`, `setDexAdapter`, `setPoolInfo`, `setWeights`, `zeroOutWeights`, `pauseAlmVault`, `unpauseAlmVault`, `restrictMint`, `rebalance`, `burnRanges`, `mintRanges`, `remintRanges`, `prepareRebalance`, `previewBurnRanges`
- Modifiers: `onlyAdmin` for `createVault`; `onlyManager` for `setPoolInfo`, `setDexAdapter`, `setWeights`, `zeroOutWeights`, `pauseAlmVault`, `unpauseAlmVault`, `restrictMint`; `onlyKeeper` for `rebalance`, `burnRanges`, `mintRanges`, `remintRanges`
 * @author BTR Team
 */

library LibALMProtected {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using SafeERC20 for IERC20;
    using ALMB for ALMVault;
    using ALMB for bytes32;
    using SW for address;
    using C for uint256;
    using U for uint32;
    using U for bytes32;
    using U for address;
    using M for uint256;
    using T for ALMVault;

    // --- DEX/POOL CONFIGURATION ---

    function setPoolInfo(
        Registry storage _reg,
        bytes32 _pid,
        address _adapter,
        address _token0,
        address _token1,
        uint24 _tickSize,
        uint32 _fee
    ) internal {
        if (_adapter == address(0)) revert Errors.ZeroAddress();
        if (_reg.poolInfo[_pid].id != bytes32(0)) {
            revert Errors.AlreadyExists(ErrorType.POOL);
        }
        uint8 decimals = IDEXAdapter(_adapter).decimals();
        _reg.poolInfo[_pid] = PoolInfo({
            id: _pid,
            adapter: _adapter,
            token0: _token0,
            token1: _token1,
            inverted: uint160(_token0) >= uint160(_token1),
            decimals: decimals,
            weiPerUnit: 10 ** decimals,
            tickSize: _tickSize,
            fee: _fee,
            cScore: 0,
            __gap: [bytes32(0), bytes32(0), bytes32(0), bytes32(0)]
        });
        _reg.dexAdapterPools[_adapter].add(_pid);
        emit Events.PoolUpdated(_pid, _adapter, _token0, _token1);
    }

    function setDexAdapter(address _oldAdapter, address _newAdapter, Registry storage _reg) internal {
        if (_newAdapter == address(0)) revert Errors.ZeroAddress();
        if (_oldAdapter == _newAdapter) revert Errors.AlreadyInitialized();

        EnumerableSet.Bytes32Set storage _oldPools = _reg.dexAdapterPools[_oldAdapter];
        EnumerableSet.Bytes32Set storage _newPools = _reg.dexAdapterPools[_newAdapter];
        uint256 _count = _oldPools.length();

        unchecked {
            for (uint256 _i = 0; _i < _count; _i++) {
                bytes32 _poolId = _oldPools.at(_i);
                _reg.poolInfo[_poolId].adapter = _newAdapter;
                _newPools.add(_poolId);
            }
        }

        // Clear the old adapter's pools
        for (uint256 _i = 0; _i < _count; _i++) {
            _oldPools.remove(_oldPools.at(0)); // Always remove first element
        }

        emit Events.DEXAdapterUpdated(_oldAdapter, _newAdapter, _count);
    }

    // --- RANGE CONFIGURATION ---

    function setWeights(ALMVault storage _vault, Registry storage _reg, uint16[] memory _weightsBp) internal {
        if (_weightsBp.length != _vault.ranges.length) {
            revert Errors.UnexpectedOutput();
        }

        uint256 _totalWeightBp;
        for (uint256 _i = 0; _i < _weightsBp.length; _i++) {
            _totalWeightBp += _weightsBp[_i];
            _reg.ranges[_vault.ranges[_i]].weightBp = _weightsBp[_i];
        }

        if (_totalWeightBp > M.BPS) {
            revert Errors.Exceeds(_totalWeightBp, M.BPS);
        }
    }

    function zeroOutWeights(ALMVault storage _vault, Registry storage _reg) internal {
        uint16[] memory _weightsBp = new uint16[](_vault.ranges.length);
        setWeights(_vault, _reg, _weightsBp);
    }

    // --- VAULT CONFIGURATION ---

    function createVault(Registry storage _reg, VaultInitParams calldata _params) internal returns (uint32 _vid) {
        if (uint160(_params.token0) >= uint160(_params.token1)) {
            revert Errors.WrongOrder(ErrorType.TOKEN);
        }

        _vid = ++_reg.vaultCount;

        ALMVault storage _vault = _reg.vaults[_vid];
        _vault.id = _vid;
        _vault.name = _params.name;
        _vault.symbol = _params.symbol;
        _vault.decimals = 18;
        _vault.token0 = IERC20(_params.token0);
        _vault.token1 = IERC20(_params.token1);
        _vault.weiPerUnit0 = 10 ** uint256(IERC20Metadata(address(_vault.token0)).decimals());
        _vault.weiPerUnit1 = 10 ** uint256(IERC20Metadata(address(_vault.token1)).decimals());

        if (_vid != 0 && _reg.vaults[0].id == 0) {
            _vault.fees = _reg.vaults[0].fees;
        }

        uint64 _timestamp = uint64(block.timestamp);
        _vault.timePoints.accruedAt = _timestamp;
        _vault.timePoints.collectedAt = _timestamp;

        if (_params.init0 > 0) {
            IERC20(_params.token0).safeTransferFrom(msg.sender, address(this), _params.init0);
            _vault.cash[address(IERC20(_params.token0))] = _params.init0;
        }

        if (_params.init1 > 0) {
            IERC20(_params.token1).safeTransferFrom(msg.sender, address(this), _params.init1);
            _vault.cash[address(IERC20(_params.token1))] = _params.init1;
        }

        if (_params.initShares > 0) {
            _vault.totalSupply = _params.initShares;
            _vault.balances[msg.sender] = _params.initShares;

            emit Events.Transfer(address(0), msg.sender, _params.initShares);
        }

        emit Events.VaultCreated(_vid, msg.sender, _params);
    }

    function restrictMint(ALMVault storage _vault, bool _restricted) internal {
        _vault.mintRestricted = _restricted;
        if (_restricted) {
            emit Events.MintRestricted(_vault.id, msg.sender);
        } else {
            emit Events.MintUnrestricted(_vault.id, msg.sender);
        }
    }

    // --- RANGE MANAGEMENT ---

    function rebalance(
        ALMVault storage _vault,
        Registry storage _reg,
        Restrictions storage _rst,
        RebalanceParams calldata _params
    ) internal returns (RebalanceProceeds memory _re) {
        if (_vault.paused) revert Errors.Paused(ErrorType.VAULT);
        BurnProceeds memory _burnResult = ALMB.burnRanges(_vault, _reg, false); // Use LibALMBase function
        _re.lpFee0 = _burnResult.lpFee0;
        _re.lpFee1 = _burnResult.lpFee1;
        (uint256 spent0, uint256 spent1) = ALMB.mintRanges(
            _vault,
            _reg,
            RebalanceParams({
                ranges: _params.ranges,
                swapInputs: _params.swapInputs,
                swapRouters: _params.swapRouters,
                swapData: _params.swapData
            }),
            false
        ); // Use LibALMBase function
        _re.spent0 = uint128(spent0);
        _re.spent1 = uint128(spent1);

        // Calculate protocol fees on LP fees
        _re.protocolFee0 = uint128(M.bpUp(uint256(_re.lpFee0), _vault.fees.perf));
        _re.protocolFee1 = uint128(M.bpUp(uint256(_re.lpFee1), _vault.fees.perf));

        // Handle any remaining swaps using LibSwap
        _handleRebalanceSwaps(_vault, _rst, _params);

        emit Events.VaultRebalanced(_vault.id, _re.spent0, _re.spent1, _re.lpFee0, _re.lpFee1);
        return _re;
    }

    function _handleRebalanceSwaps(ALMVault storage _vault, Restrictions storage _rst, RebalanceParams calldata _params)
        private
    {
        address vaultToken0 = address(_vault.token0);
        address vaultToken1 = address(_vault.token1);

        for (uint256 i = 0; i < _params.swapInputs.length; i++) {
            if (i < _params.swapData.length && _params.swapData[i].length > 0) {
                address tokenIn = _params.swapInputs[i];
                address tokenOut = tokenIn == vaultToken0 ? vaultToken1 : vaultToken0;
                address router = i < _params.swapRouters.length ? _params.swapRouters[i] : address(0);

                if (router != address(0) && IERC20(tokenIn).balanceOf(address(this)) > 0) {
                    SW.swap(_rst, tokenIn, tokenOut, router, _params.swapData[i]);
                }
            }
        }
    }

    function mintRanges(ALMVault storage _vault, Registry storage _reg, RebalanceParams calldata _params)
        internal
        returns (uint256 totalSpent0, uint256 totalSpent1)
    {
        return ALMB.mintRanges(
            _vault,
            _reg,
            RebalanceParams({
                ranges: _params.ranges,
                swapInputs: _params.swapInputs,
                swapRouters: _params.swapRouters,
                swapData: _params.swapData
            }),
            false
        );
    }

    function remintRanges(ALMVault storage _vault, Registry storage _reg)
        internal
        returns (uint256 totalSpent0, uint256 totalSpent1)
    {
        return ALMB.remintRanges(_vault, _reg);
    }

    function prepareRebalance(ALMVault storage _vault, Registry storage _reg, RangeParams[] calldata _ranges)
        internal
        view
        returns (RebalancePrep memory prep)
    {
        // Initialize prep arrays
        prep.inverted = new bool[](_ranges.length);
        prep.upperTicks = new int24[](_ranges.length);
        prep.lowerTicks = new int24[](_ranges.length);
        prep.lpNeeds = new uint256[](_ranges.length);
        prep.lpPrices0 = new uint256[](_ranges.length);
        prep.swapInputs = new address[](_ranges.length);
        prep.exactIn = new uint256[](_ranges.length);

        // Process ranges directly
        for (uint256 i = 0; i < _ranges.length; i++) {
            PoolInfo storage pool = _reg.poolInfo[_ranges[i].poolId];

            // Convert priceX96 to ticks
            (prep.lowerTicks[i], prep.upperTicks[i]) = DM.priceX96RangeToTicks(
                _ranges[i].lowerPriceX96, _ranges[i].upperPriceX96, int24(pool.tickSize), pool.inverted
            );

            prep.inverted[i] = pool.inverted;
            prep.lpNeeds[i] = _ranges[i].liquidity;

            if (_ranges[i].liquidity > 0) {
                prep.lpPrices0[i] =
                    IDEXAdapter(pool.adapter).lpPrice0(_ranges[i].poolId, prep.lowerTicks[i], prep.upperTicks[i]);
            }
        }

        // Calculate vault totals directly
        prep.totalLiq0 = _vault.cash[address(_vault.token0)];

        // Add fees from burning existing ranges
        for (uint256 i = 0; i < _vault.ranges.length; i++) {
            Range storage existingRange = _vault.ranges[i].range();

            if (existingRange.liquidity > 0) {
                PoolInfo storage pool = _reg.poolInfo[existingRange.poolId];

                (uint256 amount0,, uint256 fee0, uint256 fee1) = IDEXAdapter(pool.adapter).previewBurnRange(
                    Range({
                        id: _vault.ranges[i],
                        positionId: _vault.ranges[i],
                        poolId: existingRange.poolId,
                        vaultId: _vault.id,
                        weightBp: existingRange.weightBp,
                        inverted: pool.inverted,
                        lowerTick: existingRange.lowerTick,
                        upperTick: existingRange.upperTick,
                        liquidity: existingRange.liquidity
                    }),
                    existingRange.liquidity
                );

                prep.totalLiq0 += amount0;
                prep.fee0 += fee0;
                prep.fee1 += fee1;
            }
        }

        uint256 availableToken1 = _vault.cash[address(_vault.token1)];
        prep.vwap = prep.totalLiq0 > 0 ? (availableToken1 * 1e18) / prep.totalLiq0 : 0;
    }

    function previewBurnRanges(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1)
    {
        uint256 rangeCount = _vault.ranges.length;

        for (uint256 i = 0; i < rangeCount; i++) {
            bytes32 _rid = _vault.ranges[i];
            Range storage range = _reg.ranges[_rid];

            if (range.liquidity > 0) {
                PoolInfo storage pool = _reg.poolInfo[range.poolId];

                // Create Range struct for adapter call with all 9 fields
                Range memory rangeData = Range({
                    id: _rid,
                    positionId: _rid,
                    poolId: range.poolId,
                    vaultId: _vault.id,
                    weightBp: range.weightBp,
                    inverted: pool.inverted,
                    lowerTick: range.lowerTick,
                    upperTick: range.upperTick,
                    liquidity: range.liquidity
                });

                (uint256 amount0, uint256 amount1, uint256 lpFee0, uint256 lpFee1) =
                    IDEXAdapter(pool.adapter).previewBurnRange(rangeData, range.liquidity);

                burn0 += amount0;
                burn1 += amount1;
                fee0 += lpFee0;
                fee1 += lpFee1;
            }
        }
    }
}
