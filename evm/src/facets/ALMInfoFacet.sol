// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {
    ALMVault,
    Registry,
    Treasury,
    FeeType,
    PoolInfo,
    Range,
    ErrorType,
    MintProceeds,
    BurnProceeds
} from "@/BTRTypes.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibALMBase as ALMB} from "@libraries/LibALMBase.sol";
import {LibALMUser as ALMU} from "@libraries/LibALMUser.sol";
import {LibDEXUtils as DU} from "@libraries/LibDEXUtils.sol";
import {LibERC1155} from "@libraries/LibERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDEXAdapter as IDEX} from "@interfaces/IDEXAdapter.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title ALM Info Facet - Read-only ALM utilities
 * @copyright 2025
 * @notice Provides comprehensive read-only functions for vault information, balances, ratios, prices, and token operations
 * @dev Sub-facet for ALM view operations:
- Functions grouped by category: Protocol (`vaultCount`, `rangeCount`), ERC1155 Token Views (`name`, `symbol`, `decimals`, etc.), ALM Views (`isMintRestricted`, `token0/1`, `lpBalances`, etc.), Price Functions (`lpPrice0/1`, `poolPrice`, `vwap`)
- Provides token information, LP positions, conversion between shares and token amounts
- Extensive range and pool information utilities
- View-only, delegates to `LibALMBase`
- Tested via preview integration tests

 * @author BTR Team
 */

contract ALMInfoFacet {
    using LibERC1155 for uint32;
    using ALMB for bytes32;
    using ALMB for uint32;
    using ALMB for ALMVault;
    using U for uint32;
    using U for address;

    // --- ALM PROTOCOL INFO ---

    function vaultCount() external view returns (uint32) {
        return S.reg().vaultCount; // Returns total number of vaults
    }

    function rangeCount() external view returns (uint32) {
        return S.reg().rangeCount; // Returns total number of LP ranges
    }

    // --- ALM ERC1155 VIEWS ---

    function name(uint32 _vid) external view returns (string memory) {
        return _vid.vault().name; // Returns vault name
    }

    function symbol(uint32 _vid) external view returns (string memory) {
        return _vid.vault().symbol; // Returns vault symbol
    }

    function decimals(uint32 _vid) external view returns (uint8) {
        return _vid.vault().decimals; // Returns vault token decimals
    }

    function totalSupply(uint32 _vid) external view returns (uint256) {
        return _vid.vault().totalSupply; // Returns total outstanding shares
    }

    function maxSupply(uint32 _vid) external view returns (uint256) {
        return _vid.vault().maxSupply; // Returns maximum allowed shares
    }

    function balanceOf(uint32 _vid, address _account) external view returns (uint256) {
        return _vid.vault().balances[_account]; // Returns user's share balance
    }

    function allowance(uint32 _vid, address _owner, address _spender) external view returns (uint256) {
        return _vid.vault().allowances[_owner][_spender]; // Returns spender allowance
    }

    // --- ALM META VIEWS ---

    function isMintRestricted(uint32 _vid) external view returns (bool) {
        return _vid.vault().isMintRestricted(); // Returns mint restriction status
    }

    function isMinterUnrestricted(uint32 _vid, address _account) external view returns (bool) {
        return _vid.vault().isMinterUnrestricted(S.rst(), _account); // Returns if user is an unrestricted minter
    }

    function token0(uint32 _vid) external view returns (address) {
        return address(_vid.vault().token0); // Returns first token address
    }

    function token1(uint32 _vid) external view returns (address) {
        return address(_vid.vault().token1); // Returns second token address
    }

    // --- ALM ACCOUNTING VIEWS ---

    function totalBalances(uint32 _vid) external view returns (uint256 balance0, uint256 balance1) {
        return _vid.vault().totalBalances(S.reg());
    }

    function lpBalances(uint32 _vid) external view returns (uint256 balance0, uint256 balance1) {
        return _vid.vault().lpBalances(S.reg());
    }

    function cash0(uint32 _vid) external view returns (uint256) {
        return _vid.vault().cash0(); // Returns token0 cash balance
    }

    function cash1(uint32 _vid) external view returns (uint256) {
        return _vid.vault().cash1(); // Returns token1 cash balance
    }

    function weights(uint32 _vid) external view returns (uint16[] memory) {
        return _vid.vault().weights(S.reg()); // Returns range allocation weights
    }

    function targetRatio0(uint32 _vid) external view returns (uint256 targetPBp0) {
        return _vid.vault().targetRatio0(S.reg());
    }

    function targetRatio1(uint32 _vid) external view returns (uint256 targetPBp1) {
        return _vid.vault().targetRatio1(S.reg());
    }

    function ratios0(uint32 _vid) external view returns (uint256[] memory) {
        return _vid.vault().ratios0(S.reg());
    }

    function ratios1(uint32 _vid) external view returns (uint256[] memory) {
        return _vid.vault().ratios1(S.reg());
    }

    // --- SHARE/AMOUNT CONVERSIONS ---

    function sharesToGrossAmounts(uint32 _vid, uint256 _shares)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        Treasury storage tres = S.tres();
        (amount0, amount1,,) = vault.sharesToAmounts(reg, tres, _shares, FeeType.NONE, address(0));
    }

    function sharesToAmounts(uint32 _vid, uint256 _shares, FeeType _feeType)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        Treasury storage tres = S.tres();
        (amount0, amount1, fee0, fee1) = vault.sharesToAmounts(reg, tres, _shares, _feeType, msg.sender);
    }

    function amountsToGrossShares(uint32 _vid, uint256 _amount0, uint256 _amount1)
        external
        view
        returns (uint256 shares)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        Treasury storage tres = S.tres();
        (shares,,,) = vault.amountsToShares(reg, tres, _amount0, _amount1, FeeType.NONE, address(0));
    }

    function amountsToShares(uint32 _vid, uint256 _amount0, uint256 _amount1, FeeType _feeType, address _receiver)
        external
        view
        returns (uint256 shares, uint256 fee0, uint256 fee1, int256 rd0)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        Treasury storage tres = S.tres();
        return vault.amountsToShares(reg, tres, _amount0, _amount1, _feeType, _receiver);
    }

    // --- ALM ACTION PREVIEWS ---

    function previewMint(uint32 _vid, uint256 _mintShares)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        // Use simplified preview logic for view function
        (amount0, amount1, fee0, fee1) = vault.sharesToAmounts(reg, S.tres(), _mintShares, FeeType.ENTRY, msg.sender);
    }

    function previewDeposit(uint32 _vid, uint256 _amount0, uint256 _amount1)
        external
        view
        returns (uint256 mintShares, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        (mintShares, fee0, fee1,) = vault.amountsToShares(reg, S.tres(), _amount0, _amount1, FeeType.ENTRY, msg.sender);
    }

    function previewDepositExact0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        view
        returns (uint256 amount1, uint256 mintShares, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        uint256 ratio0 = vault.targetRatio0(reg);
        if (_amount0 == 0 || ratio0 == 10000) {
            return (0, 0, 0, 0);
        }
        amount1 = (10000 - ratio0) * _amount0 / ratio0;
        (mintShares, fee0, fee1,) = vault.amountsToShares(reg, S.tres(), _amount0, amount1, FeeType.ENTRY, _receiver);
    }

    function previewDepositExact1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        view
        returns (uint256 amount0, uint256 mintShares, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        uint256 ratio1 = vault.targetRatio1(reg);
        if (_amount1 == 0 || ratio1 == 10000) {
            return (0, 0, 0, 0);
        }
        amount0 = (10000 - ratio1) * _amount1 / ratio1;
        (mintShares, fee0, fee1,) = vault.amountsToShares(reg, S.tres(), amount0, _amount1, FeeType.ENTRY, _receiver);
    }

    function previewDepositMax(uint32 _vid, address _payer, address /* _receiver */ )
        external
        view
        returns (uint256 deposit0, uint256 deposit1)
    {
        ALMVault storage vault = _vid.vault();
        deposit0 = vault.token0.balanceOf(_payer);
        deposit1 = vault.token1.balanceOf(_payer);
    }

    function previewWithdraw(uint32 _vid, uint256 _burntShares, address _receiver)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        (amount0, amount1, fee0, fee1) = vault.sharesToAmounts(S.reg(), S.tres(), _burntShares, FeeType.EXIT, _receiver);
    }

    function previewWithdraw(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        view
        returns (uint256 burntShares, uint256 fee0, uint256 fee1)
    {
        (burntShares, fee0, fee1,) =
            _vid.vault().amountsToShares(S.reg(), S.tres(), _amount0, _amount1, FeeType.EXIT, _receiver);
    }

    function previewWithdrawExact0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        view
        returns (uint256 amount1, uint256 burntShares, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        uint256 ratio0 = vault.targetRatio0(reg);
        if (_amount0 == 0 || ratio0 == 10000) {
            return (0, 0, 0, 0);
        }
        amount1 = (10000 - ratio0) * _amount0 / ratio0;
        (burntShares,,,) = vault.amountsToShares(reg, S.tres(), _amount0, amount1, FeeType.EXIT, _receiver);
    }

    function previewWithdrawExact1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        view
        returns (uint256 amount0, uint256 burntShares, uint256 fee0, uint256 fee1)
    {
        ALMVault storage vault = _vid.vault();
        Registry storage reg = S.reg();
        uint256 ratio1 = vault.targetRatio1(reg);
        if (_amount1 == 0 || ratio1 == 10000) {
            return (0, 0, 0, 0);
        }
        amount0 = (10000 - ratio1) * _amount1 / ratio1;
        (burntShares,,,) = vault.amountsToShares(reg, S.tres(), amount0, _amount1, FeeType.EXIT, _receiver);
    }

    function previewDepositSingle0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        view
        returns (uint256 mintedShares, uint256 fee0, uint256 fee1, int256 rd0)
    {
        return _vid.vault().amountsToShares(S.reg(), S.tres(), _amount0, 0, FeeType.ENTRY, _receiver);
    }

    function previewDepositSingle1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        view
        returns (uint256 mintedShares, uint256 fee0, uint256 fee1, int256 rd0)
    {
        return _vid.vault().amountsToShares(S.reg(), S.tres(), 0, _amount1, FeeType.ENTRY, _receiver);
    }

    function previewWithdrawSingle0(uint32 _vid, uint256 _shares, address _receiver)
        external
        view
        returns (uint256 amount0, uint256 fee0, uint256 fee1, int256 rd0)
    {
        return _vid.vault().sharesToAmount0(S.reg(), S.tres(), _shares, FeeType.EXIT, _receiver);
    }

    function previewWithdrawSingle1(uint32 _vid, uint256 _shares, address _receiver)
        external
        view
        returns (uint256 amount1, uint256 fee0, uint256 fee1, int256 rd0)
    {
        return _vid.vault().sharesToAmount1(S.reg(), S.tres(), _shares, FeeType.EXIT, _receiver);
    }

    // --- ALM POOL/DEX INFO ---

    function poolInfo(bytes32 _pid) external view returns (PoolInfo memory) {
        return _pid.poolInfo(S.reg());
    }

    // --- ALM RANGE INFO ---

    function range(bytes32 _rid) external view returns (Range memory) {
        return _rid.range(S.reg()); // Ensuring this also calls Base directly for consistency
    }

    function vaultRangeIds(uint32 _vid) external view returns (bytes32[] memory) {
        return _vid.vault().ranges; // Returns vault's range identifiers
    }

    function ranges(uint32 _vid) external view returns (Range[] memory r) {
        bytes32[] memory rids = _vid.vault().ranges;
        r = new Range[](rids.length);
        unchecked {
            for (uint256 i = 0; i < rids.length; i++) {
                r[i] = S.reg().ranges[rids[i]]; // Populate range configurations
            }
        }
    }

    function rangeDexAdapter(bytes32 _rid) external view returns (address) {
        return address(_rid.rangeDexAdapter(S.reg()));
    }

    function rangeRatio0(bytes32 _rid) external view returns (uint256 ratioPBp0) {
        return ALMB.rangeRatio0(_rid, S.reg(), address(_rid.rangeDexAdapter(S.reg())));
    }

    function rangeRatio1(bytes32 _rid) external view returns (uint256 ratioPBp1) {
        return ALMB.rangeRatio1(_rid, S.reg(), address(_rid.rangeDexAdapter(S.reg())));
    }

    // --- ALM PRICE FUNCTIONS ---

    function lpPrice0(bytes32 _rid) external view returns (uint256) {
        return ALMB.lpPrice0(_rid, S.reg(), address(_rid.rangeDexAdapter(S.reg())));
    }

    function lpPrice1(bytes32 _rid) external view returns (uint256) {
        return ALMB.lpPrice1(_rid, S.reg(), address(_rid.rangeDexAdapter(S.reg())));
    }

    function matchTokens(uint32 _vid, bytes32 _pid) external view returns (bool matched, bool inverted) {
        ALMVault storage vault = _vid.vault();
        PoolInfo memory pool = _pid.poolInfo(S.reg());
        return DU.matchTokens(address(vault.token0), address(vault.token1), pool.token0, pool.token1);
    }

    function poolPrice(bytes32 _pid) external view returns (uint256) {
        return _pid.poolPrice(S.reg());
    }

    function vwap(uint32 _vid) external view returns (uint256) {
        return _vid.vault().vwap(S.reg(), true);
    }
}
