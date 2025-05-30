// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {CoreStorage, Fees, ErrorType, ALMVault, Registry, Oracles} from "@/BTRTypes.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibMaths as M} from "@libraries/LibMaths.sol";
import {LibOracle as O} from "@libraries/LibOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Metrics Library - Protocol metrics and analytics
 * @copyright 2025
 * @notice Contains functions for calculating protocol metrics and performance analytics
 * @dev Used for protocol monitoring and analytics
 * @author BTR Team
 */

library LibMetrics {
    using U for uint32;
    using U for address;
    using M for uint256;
    using O for address;
    using ALMB for ALMVault;

    function almTvlUsd(ALMVault storage _vault, Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256 balance0, uint256 balance1, uint256 balanceUsd0, uint256 balanceUsd1)
    {
        (balance0, balance1) = _vault.totalBalances(_reg);
        (balanceUsd0, balanceUsd1) =
            (O.toUsd(_ora, address(_vault.token0), balance0), O.toUsd(_ora, address(_vault.token1), balance1));
    }

    function almTvlEth(ALMVault storage _vault, Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256 balance0, uint256 balance1, uint256 balanceEth0, uint256 balanceEth1)
    {
        (balance0, balance1) = _vault.totalBalances(_reg);
        (balanceEth0, balanceEth1) =
            (O.toEth(_ora, address(_vault.token0), balance0), O.toEth(_ora, address(_vault.token1), balance1));
    }

    function almTvlBtc(ALMVault storage _vault, Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256 balance0, uint256 balance1, uint256 balanceBtc0, uint256 balanceBtc1)
    {
        (balance0, balance1) = _vault.totalBalances(_reg);
        (balanceBtc0, balanceBtc1) =
            (O.toBtc(_ora, address(_vault.token0), balance0), O.toBtc(_ora, address(_vault.token1), balance1));
    }

    function totalAlmTvlUsd(Registry storage _registry, Oracles storage _ora)
        internal
        view
        returns (uint256 totalValueUsd)
    {
        unchecked {
            for (uint256 i = 0; i < _registry.vaultCount; i++) {
                (,, uint256 totalValueUsd0, uint256 totalValueUsd1) =
                    almTvlUsd(_registry.vaults[uint32(i)], _registry, _ora);
                totalValueUsd += totalValueUsd0 + totalValueUsd1;
            }
        }
    }

    function totalAlmTvlEth(Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256 totalValueEth)
    {
        unchecked {
            for (uint256 i = 0; i < _reg.vaultCount; i++) {
                (,, uint256 totalValueEth0, uint256 totalValueEth1) = almTvlEth(_reg.vaults[uint32(i)], _reg, _ora);
                totalValueEth += totalValueEth0 + totalValueEth1;
            }
        }
    }

    function totalAlmTvlBtc(Registry storage _reg, Oracles storage _ora)
        internal
        view
        returns (uint256 totalValueBtc)
    {
        unchecked {
            for (uint256 i = 0; i < _reg.vaultCount; i++) {
                (,, uint256 totalValueBtc0, uint256 totalValueBtc1) = almTvlBtc(_reg.vaults[uint32(i)], _reg, _ora);
                totalValueBtc += totalValueBtc0 + totalValueBtc1;
            }
        }
    }
}
