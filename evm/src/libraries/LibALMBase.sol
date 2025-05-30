// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    ALMVault,
    PoolInfo,
    Range,
    RangeParams,
    CoreStorage,
    Registry,
    FeeType,
    ErrorType,
    RebalanceParams,
    Fees,
    Restrictions,
    Treasury,
    MintProceeds,
    BurnProceeds
} from "@/BTRTypes.sol";
import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibCast as C} from "@libraries/LibCast.sol";
import {LibDEXMaths as DM} from "@libraries/LibDEXMaths.sol";
import {LibDEXUtils as DU} from "@libraries/LibDEXUtils.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibTreasury as T} from "@libraries/LibTreasury.sol";
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
 * @title ALM Base Library - ALM base logic
 * @copyright 2025
 * @notice Contains internal functions for ALM base logic
 * @dev Base library for ALM operations and calculations
 * @author BTR Team
 */

library LibALMBase {
    using SafeERC20 for IERC20;
    using LibERC1155 for uint32;
    using C for uint256;
    using U for uint32;
    using U for address;
    using U for bytes32;
    using M for uint256;
    using M for int256;
    using T for ALMVault;

    // --- POOL ---

    function poolInfo(bytes32 _pid, Registry storage _reg) internal view returns (PoolInfo memory) {
        PoolInfo memory info = _reg.poolInfo[_pid];
        if (info.id == bytes32(0)) revert Errors.NotFound(ErrorType.POOL);
        if (info.adapter == address(0)) revert Errors.NotInitialized(); // Ensure adapter is set
        return info;
    }

    // --- RANGE ---

    function range(bytes32 _rid, Registry storage _reg) internal view returns (Range memory) {
        Range memory r = _reg.ranges[_rid];
        if (r.id == bytes32(0)) revert Errors.NotFound(ErrorType.RANGE);
        return r;
    }

    function rangeDexAdapter(bytes32 _rid, Registry storage _reg) internal view returns (IDEXAdapter) {
        return IDEXAdapter(poolInfo(range(_rid, _reg).poolId, _reg).adapter);
    }

    function rangeDexAdapter(Range storage _range, Registry storage _reg) internal view returns (IDEXAdapter) {
        return IDEXAdapter(poolInfo(_range.poolId, _reg).adapter);
    }

    function rangeRatio0(bytes32 _rid, Registry storage _reg, address _adapter)
        internal
        view
        returns (uint256 ratio0)
    {
        Range memory r = range(_rid, _reg);
        ratio0 = IDEXAdapter(_adapter).liquidityRatio0(r.poolId, r.lowerTick, r.upperTick, uint128(M.PREC_BPS));
    }

    function rangeRatio1(bytes32 _rid, Registry storage _reg, address _adapter)
        internal
        view
        returns (uint256 ratio1)
    {
        return M.subMax0(M.PREC_BPS, rangeRatio0(_rid, _reg, _adapter)); // 100% - ratio0
    }

    function _transferAndMint(
        ALMVault storage _vault,
        Registry storage _reg,
        Range storage _range,
        MintProceeds memory _res
    ) private {
        PoolInfo storage pool = _reg.poolInfo[_range.poolId];

        // Transfer tokens to adapter for minting
        if (_res.spent0 > 0) _vault.token0.safeTransfer(pool.adapter, _res.spent0);
        if (_res.spent1 > 0) _vault.token1.safeTransfer(pool.adapter, _res.spent1);

        (, uint128 liquidity, uint256 actualSpent0, uint256 actualSpent1) =
            IDEXAdapter(pool.adapter).mintRange(_range, address(this), "");
        _range.liquidity = liquidity;
        _vault.cash[address(_vault.token0)] -= actualSpent0;
        _vault.cash[address(_vault.token1)] -= actualSpent1;

        // Update the result with actual spent amounts
        _res.spent0 = actualSpent0;
        _res.spent1 = actualSpent1;
    }

    function mintRange(ALMVault storage _vault, Registry storage _reg, RangeParams memory _range, bool _push)
        internal
        returns (MintProceeds memory _res)
    {
        PoolInfo storage pool = _reg.poolInfo[_range.poolId];

        // Convert price to ticks
        (int24 lowerTick, int24 upperTick) =
            DM.priceX96RangeToTicks(_range.lowerPriceX96, _range.upperPriceX96, int24(pool.tickSize), pool.inverted);

        // Generate range ID
        bytes32 rangeId = keccak256(abi.encodePacked(_vault.id, _range.poolId, lowerTick, upperTick));

        Range storage r = _reg.ranges[rangeId];
        if (r.id == bytes32(0)) {
            r.id = rangeId;
            r.positionId = rangeId;
            r.vaultId = _vault.id;
            r.poolId = _range.poolId;
            r.inverted = pool.inverted;
            r.lowerTick = lowerTick;
            r.upperTick = upperTick;
            _reg.rangeCount++;
        }
        r.liquidity = _range.liquidity;
        r.weightBp = _range.weightBp;
        if (_push) {
            _vault.ranges.push(rangeId);
        }

        (_res.spent0, _res.spent1) =
            rangeDexAdapter(r, _reg).liquidityToAmountsTicks(_range.poolId, r.lowerTick, r.upperTick, _range.liquidity);
        _transferAndMint(_vault, _reg, r, _res);
    }

    function mintRanges(
        ALMVault storage _vault,
        Registry storage _reg,
        RebalanceParams memory _rebalanceData,
        bool _push
    ) internal returns (uint256 totalSpent0, uint256 totalSpent1) {
        uint256 rangeCount = _rebalanceData.ranges.length;
        unchecked {
            for (uint256 i = 0; i < rangeCount; ++i) {
                MintProceeds memory result = mintRange(_vault, _reg, _rebalanceData.ranges[i], _push);
                totalSpent0 += result.spent0;
                totalSpent1 += result.spent1;
            }
        }
    }

    function remintRange(ALMVault storage _vault, Registry storage _reg, bytes32 _rid)
        internal
        returns (uint256 spent0, uint256 spent1)
    {
        Range memory r = range(_rid, _reg);
        PoolInfo memory pool = poolInfo(r.poolId, _reg);

        // Calculate and transfer required amounts for the existing liquidity
        (uint256 amount0Required, uint256 amount1Required) =
            IDEXAdapter(pool.adapter).liquidityToAmountsTicks(r.poolId, r.lowerTick, r.upperTick, uint128(r.liquidity));

        // Transfer tokens to adapter for reminting
        if (amount0Required > 0) {
            _vault.token0.safeTransfer(pool.adapter, amount0Required);
        }
        if (amount1Required > 0) {
            _vault.token1.safeTransfer(pool.adapter, amount1Required);
        }

        // Mint the range
        (,, spent0, spent1) = IDEXAdapter(pool.adapter).mintRange(r, address(this), "");

        // Update cash balances
        _vault.cash[address(_vault.token0)] -= spent0;
        _vault.cash[address(_vault.token1)] -= spent1;
    }

    function remintRanges(ALMVault storage _vault, Registry storage _reg)
        internal
        returns (uint256 totalSpent0, uint256 totalSpent1)
    {
        uint256 rangeCount = _vault.ranges.length;
        unchecked {
            for (uint256 i = 0; i < rangeCount; ++i) {
                (uint256 spent0, uint256 spent1) = remintRange(_vault, _reg, _vault.ranges[i]);
                totalSpent0 += spent0;
                totalSpent1 += spent1;
            }
        }
    }

    function burnRange(ALMVault storage _vault, Registry storage _reg, uint256 _index, bool _pop)
        internal
        returns (BurnProceeds memory _res)
    {
        Range storage r = _reg.ranges[_vault.ranges[_index]];
        if (r.id == bytes32(0)) revert Errors.NotFound(ErrorType.RANGE);

        if (r.liquidity > 0) {
            // Burn only if liquidity exists
            PoolInfo memory pool = poolInfo(r.poolId, _reg);
            Range memory rangeData = r;
            (uint256 recovered0, uint256 recovered1, uint256 lpFee0, uint256 lpFee1) =
                IDEXAdapter(pool.adapter).burnRange(rangeData, address(this), "");
            _res.recovered0 = recovered0;
            _res.recovered1 = recovered1;
            _res.lpFee0 = uint128(lpFee0);
            _res.lpFee1 = uint128(lpFee1);
        }

        if (_pop) {
            // Pop at rebalance to close range
            delete _reg.ranges[r.id]; // Remove range from registry
            if (_reg.rangeCount > 0) _reg.rangeCount--; // Decrement range count
            uint256 lastIndex = _vault.ranges.length - 1; // Get last index
            if (_index < lastIndex) _vault.ranges[_index] = _vault.ranges[lastIndex]; // Swap with last element
            _vault.ranges.pop(); // Remove last element
        }

        _vault.cash[address(_vault.token0)] += _res.recovered0; // Update token0 cash balance
        _vault.cash[address(_vault.token1)] += _res.recovered1; // Update token1 cash balance
    }

    function burnRanges(ALMVault storage _vault, Registry storage _reg, bool _pop)
        internal
        returns (BurnProceeds memory _total)
    {
        uint256 length = _vault.ranges.length;
        for (uint256 i = length; i > 0; i--) {
            BurnProceeds memory _res = burnRange(_vault, _reg, i - 1, _pop);
            _total.recovered0 += _res.recovered0;
            _total.recovered1 += _res.recovered1;
            _total.lpFee0 += _res.lpFee0;
            _total.lpFee1 += _res.lpFee1;
        }
        _vault.accrueAlmFees(_reg, _total.lpFee0, _total.lpFee1);
    }

    // --- VAULT ---

    function isMintRestricted(ALMVault storage _vault) internal view returns (bool) {
        return _vault.mintRestricted;
    }

    function isMinterUnrestricted(ALMVault storage _vault, Restrictions storage _rs, address _minter)
        internal
        view
        returns (bool)
    {
        return AC.isAlmMinterUnrestricted(_rs, _vault.id, _minter);
    }

    function cash0(ALMVault storage _vault) internal view returns (uint256) {
        return _vault.cash[address(_vault.token0)];
    }

    function cash1(ALMVault storage _vault) internal view returns (uint256) {
        return _vault.cash[address(_vault.token1)];
    }

    function lpBalances(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256 balance0, uint256 balance1)
    {
        for (uint256 i = 0; i < _vault.ranges.length; i++) {
            Range memory r = range(_vault.ranges[i], _reg);
            if (r.liquidity == 0) continue; // Skip ranges with no liquidity

            PoolInfo memory pool = poolInfo(r.poolId, _reg);
            (uint256 position0, uint256 position1) = IDEXAdapter(pool.adapter).liquidityToAmountsTicks(
                r.poolId, r.lowerTick, r.upperTick, uint128(r.liquidity)
            );
            balance0 += position0;
            balance1 += position1;
        }
    }

    function totalBalances(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256 balance0, uint256 balance1)
    {
        // Get LP position balances
        (uint256 lp0, uint256 lp1) = lpBalances(_vault, _reg);

        // Add cash balances
        balance0 = lp0 + cash0(_vault);
        balance1 = lp1 + cash1(_vault);
    }

    function weights(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint16[] memory weightsBp0)
    {
        uint256 rangeCount = _vault.ranges.length;
        weightsBp0 = new uint16[](rangeCount);
        for (uint256 i = 0; i < rangeCount; i++) {
            bytes32 rid = _vault.ranges[i];
            Range storage r = _reg.ranges[rid];
            if (r.id != bytes32(0)) {
                weightsBp0[i] = r.weightBp;
            }
        }
    }

    function ratios0(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256[] memory ratiosPBp1)
    {
        uint256 rangeCount = _vault.ranges.length;
        ratiosPBp1 = new uint256[](rangeCount);
        if (rangeCount == 0) return ratiosPBp1;
        unchecked {
            for (uint256 i = 0; i < rangeCount; i++) {
                Range memory r = _reg.ranges[_vault.ranges[i]]; // bypass the rid 0 revert check from rid.range()
                if (r.id != bytes32(0)) {
                    ratiosPBp1[i] = rangeRatio0(r.id, _reg, poolInfo(r.poolId, _reg).adapter);
                }
            }
        }
    }

    function ratios1(ALMVault storage _vault, Registry storage _reg)
        internal
        view
        returns (uint256[] memory ratiosPBp1)
    {
        uint256[] memory r0 = ratios0(_vault, _reg);
        uint256 length = r0.length;
        ratiosPBp1 = new uint256[](length);
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                ratiosPBp1[i] = M.subMax0(M.PREC_BPS, r0[i]);
            }
        }
    }

    function targetRatio0(ALMVault storage _vault, Registry storage _reg) internal view returns (uint256 targetPBp0) {
        uint256 rangeCount = _vault.ranges.length;
        if (rangeCount == 0) return 0;

        uint256[] memory r0 = ratios0(_vault, _reg);
        uint16[] memory weightsBp = weights(_vault, _reg);
        if (r0.length != rangeCount || weightsBp.length != rangeCount) {
            revert Errors.UnexpectedInput();
        }
        unchecked {
            for (uint256 i = 0; i < rangeCount; i++) {
                if (weightsBp[i] > 0) {
                    targetPBp0 += r0[i].mulDivDown(weightsBp[i], M.BPS);
                }
            }
        }
        targetPBp0 = M.min(targetPBp0, M.PREC_BPS);
    }

    function targetRatio1(ALMVault storage _vault, Registry storage _reg) internal view returns (uint256 targetPBp1) {
        return M.subMax0(M.PREC_BPS, targetRatio0(_vault, _reg));
    }

    function poolPrice(bytes32 _pid, Registry storage _reg) internal view returns (uint256) {
        PoolInfo memory pool = poolInfo(_pid, _reg);
        return IDEXAdapter(pool.adapter).poolPrice(_pid);
    }

    function safePoolPrice(bytes32 _pid, Registry storage _reg, uint32 _lookback, uint256 _maxDeviationBp)
        internal
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo(_pid, _reg);
        return IDEXAdapter(pool.adapter).safePoolPrice(_pid, _lookback, _maxDeviationBp);
    }

    function vwap(RangeParams[] memory _ranges, Registry storage _reg, bool _safe)
        internal
        view
        returns (uint256 price)
    {
        uint256 totalWeightBp = 0;
        uint256 weightedSum = 0;
        unchecked {
            for (uint256 i = 0; i < _ranges.length; i++) {
                if (_ranges[i].weightBp == 0) continue;
                bytes32 poolId = _ranges[i].poolId;
                weightedSum += (
                    _safe
                        ? safePoolPrice(poolId, _reg, 900, 200) // <2% drift in 15 minutes
                        : poolPrice(poolId, _reg)
                ) * _ranges[i].weightBp;
                totalWeightBp += _ranges[i].weightBp; // Accumulate total weight
            }
        }
        if (totalWeightBp > 0) {
            price = weightedSum / totalWeightBp; // Calculate VWAP
        }
        if (_safe && price == 0) revert Errors.StalePrice();
    }

    function vwap(bytes32[] storage _rids, Registry storage _reg, bool _safe) internal view returns (uint256 price) {
        uint256 totalWeightBp = 0;
        uint256 weightedSum = 0;

        unchecked {
            for (uint256 i = 0; i < _rids.length; i++) {
                bytes32 rid = _rids[i];
                Range memory r = _reg.ranges[rid];
                if (r.id == bytes32(0) || r.weightBp == 0) continue;
                weightedSum += (
                    _safe
                        ? safePoolPrice(r.poolId, _reg, 900, 200) // <2% drift in 15 minutes
                        : poolPrice(r.poolId, _reg)
                ) * r.weightBp;
                totalWeightBp += r.weightBp; // Accumulate total weight
            }
        }

        if (totalWeightBp > 0) {
            price = weightedSum / totalWeightBp; // Calculate VWAP
        }
        if (_safe && price == 0) revert Errors.StalePrice();
    }

    function vwap(ALMVault storage _vault, Registry storage _reg, bool _safe) internal view returns (uint256 price) {
        return vwap(_vault.ranges, _reg, _safe);
    }

    function lpPrice0(bytes32 _rid, Registry storage _reg, address _adapter) internal view returns (uint256 lpPrice) {
        Range memory r = range(_rid, _reg);
        lpPrice = IDEXAdapter(_adapter).lpPrice0(r.poolId, r.lowerTick, r.upperTick);
    }

    function lpPrice1(bytes32 _rid, Registry storage _reg, address _adapter) internal view returns (uint256 lpPrice) {
        Range memory r = range(_rid, _reg);
        lpPrice = IDEXAdapter(_adapter).lpPrice1(r.poolId, r.lowerTick, r.upperTick);
    }

    function applyActionFees(uint256 _gross0, uint256 _gross1, uint16 _fee, bool _reverse)
        internal
        pure
        returns (uint256 net0, uint256 net1, uint256 fee0, uint256 fee1)
    {
        if (_fee > 0) {
            if (_reverse) {
                (fee0, fee1) = (_gross0.revBpUp(_fee), _gross1.revBpUp(_fee));
                (net0, net1) = (_gross0 + fee0, _gross1 + fee1);
            } else {
                (fee0, fee1) = (_gross0.bpUp(_fee), _gross1.bpUp(_fee));
                (net0, net1) = (M.subMax0(_gross0, fee0), M.subMax0(_gross1, fee1));
            }
        } else {
            (net0, net1) = (_gross0, _gross1);
        }
    }

    function ratioDiff0(
        ALMVault storage _vault,
        Registry storage _reg,
        uint256 _balance0,
        uint256 _balance1,
        int256 _diff0,
        int256 _diff1
    ) internal view returns (int16 ratioDiff0Bp) {
        uint256 targetRatio0Val = targetRatio0(_vault, _reg); // Target in BPS
        uint256 oldRatio0 = _balance0.mulDivDown(M.BPS, _balance0 + _balance1); // current ratio
        _balance0 = _diff0 >= 0 ? _balance0 + uint256(_diff0) : _balance0 - uint256(-_diff0); // New balance0
        _balance1 = _diff1 >= 0 ? _balance1 + uint256(_diff1) : _balance1 - uint256(-_diff1); // New balance1
        uint256 newRatio0 = _balance0.mulDivDown(M.BPS, _balance0 + _balance1);
        int256 rd0 = int256(oldRatio0.diff(targetRatio0Val)) - int256(newRatio0.diff(targetRatio0Val));
        rd0 = rd0.max(-int256(M.BPS)).min(int256(M.BPS)); // Cap to ±BPS (should always be true)
        ratioDiff0Bp = int16(rd0); // Safe cast since capped to ±BPS
    }

    function amountsToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage, /* _tres */
        uint256 _amount0,
        uint256 _amount1,
        FeeType _feeType,
        address /* _user */
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int16 ratioDiff0Bp) {
        if (_amount0 + _amount1 == 0) return (0, 0, 0, 0);
        (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);

        if (_vault.totalSupply == 0 || balance0 + balance1 == 0) {
            revert Errors.NotInitialized();
        }

        // Simplified fee handling - TODO: restore complex fee logic after compilation fix
        if (_feeType != FeeType.NONE) {
            // Simplified 1% fee for now
            fee0 = _amount0 / 100;
            fee1 = _amount1 / 100;
            if (_feeType == FeeType.EXIT) {
                _amount0 += fee0;
                _amount1 += fee1;
            } else {
                _amount0 = M.subMax0(_amount0, fee0);
                _amount1 = M.subMax0(_amount1, fee1);
            }
        }

        // Calculate shares using VWAP
        uint256 price = vwap(_vault, _reg, true);
        shares = (_amount0 + _amount1.mulDivDown(M.WAD, price)).mulDivDown(
            _vault.totalSupply, balance0 + balance1.mulDivDown(M.WAD, price)
        );

        // Calculate ratio difference
        ratioDiff0Bp = ratioDiff0(_vault, _reg, balance0, balance1, int256(_amount0), int256(_amount1));
    }

    function amount0ToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage _tres,
        uint256 _amount0,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int16 ratioDiff0Bp) {
        (shares, fee0, fee1, ratioDiff0Bp) = amountsToShares(_vault, _reg, _tres, _amount0, 0, _feeType, _user);
    }

    function amount1ToShares(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage _tres,
        uint256 _amount1,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 shares, uint256 fee0, uint256 fee1, int16 ratioDiff0Bp) {
        (shares, fee0, fee1, ratioDiff0Bp) = amountsToShares(_vault, _reg, _tres, 0, _amount1, _feeType, _user);
    }

    function sharesToAmounts(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage, /* _tres */
        uint256 _shares,
        FeeType _feeType,
        address /* _user */
    ) internal view returns (uint256 net0, uint256 net1, uint256 fee0, uint256 fee1) {
        if (_shares == 0) return (0, 0, 0, 0);
        (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
        if (_vault.totalSupply == 0 || balance0 + balance1 == 0) {
            revert Errors.NotInitialized();
        }
        uint256 gross0 = balance0.mulDivUp(_shares, _vault.totalSupply);
        uint256 gross1 = balance1.mulDivUp(_shares, _vault.totalSupply);

        if (_feeType == FeeType.NONE) {
            (net0, net1) = (gross0, gross1);
        } else {
            // Simplified 1% fee for now - TODO: restore complex fee logic after compilation fix
            fee0 = gross0 / 100;
            fee1 = gross1 / 100;
            if (_feeType == FeeType.ENTRY) {
                net0 = gross0 + fee0;
                net1 = gross1 + fee1;
            } else {
                net0 = M.subMax0(gross0, fee0);
                net1 = M.subMax0(gross1, fee1);
            }
        }
    }

    function sharesToAmount0(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage _tres,
        uint256 _shares,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 amount0, uint256 fee0, uint256 fee1, int16 ratioDiff0Bp) {
        uint256 amount1;
        (amount0, amount1, fee0, fee1) = sharesToAmounts(_vault, _reg, _tres, _shares, _feeType, _user);

        uint256 price = vwap(_vault, _reg, true); // Reverts if stale
        uint256 total0Equivalent = amount0 + amount1.mulDivDown(M.WAD, price);
        amount0 = total0Equivalent;

        (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
        ratioDiff0Bp = ratioDiff0(_vault, _reg, balance0, balance1, -int256(amount0), 0);
    }

    function sharesToAmount1(
        ALMVault storage _vault,
        Registry storage _reg,
        Treasury storage _tres,
        uint256 _shares,
        FeeType _feeType,
        address _user
    ) internal view returns (uint256 amount1, uint256 fee0, uint256 fee1, int16 ratioDiff0Bp) {
        uint256 amount0;
        (amount0, amount1, fee0, fee1) = sharesToAmounts(_vault, _reg, _tres, _shares, _feeType, _user);

        uint256 price = vwap(_vault, _reg, true);
        amount1 = amount1 + amount0.mulDivDown(price, M.WAD); // shares value in token1

        (uint256 balance0, uint256 balance1) = totalBalances(_vault, _reg);
        ratioDiff0Bp = ratioDiff0(_vault, _reg, balance0, balance1, 0, -int256(amount1));
    }
}
