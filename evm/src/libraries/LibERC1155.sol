// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {ErrorType, CoreStorage, ALMVault, Restrictions} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BTRUtils as U} from "@libraries/BTRUtils.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
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
 * @title ERC1155 Library - ERC1155 token interaction logic
 * @copyright 2025
 * @notice Contains internal functions for managing ERC1155 vault tokens
 * @dev Helper library for vault token operations (minting, burning, transfers)
 * @author BTR Team
 */

library LibERC1155 {
    using SafeERC20 for IERC20;
    using U for uint32;

    function name(ALMVault storage _vault) internal view returns (string memory) {
        return _vault.name;
    }

    function symbol(ALMVault storage _vault) internal view returns (string memory) {
        return _vault.symbol;
    }

    function decimals(ALMVault storage _vault) internal view returns (uint8) {
        return _vault.decimals;
    }

    function totalSupply(ALMVault storage _vault) internal view returns (uint256) {
        return _vault.totalSupply;
    }

    function maxSupply(ALMVault storage _vault) internal view returns (uint256) {
        return _vault.maxSupply;
    }

    function balanceOf(ALMVault storage _vault, address _account) internal view returns (uint256) {
        return _vault.balances[_account];
    }

    function allowance(ALMVault storage _vault, address _owner, address _spender) internal view returns (uint256) {
        return _vault.allowances[_owner][_spender];
    }

    function setMaxSupply(ALMVault storage _vault, uint256 _maxSupply) internal {
        _vault.maxSupply = _maxSupply;
        emit Events.MaxSupplyUpdated(_vault.id, _maxSupply);
    }

    function approve(ALMVault storage _vault, address _owner, address _spender, uint256 _amount) internal {
        if (_spender == address(0)) revert Errors.ZeroAddress();
        _vault.allowances[_owner][_spender] = _amount;
        emit Events.Approval(_owner, _spender, _amount);
    }

    function transferFrom(
        ALMVault storage _vault,
        Restrictions storage _rs,
        address _operator,
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        AC.checkAlmMinterUnrestricted(_rs, _vault.id, _recipient);
        if (_sender != _operator) {
            uint256 currentAllowance = _vault.allowances[_sender][_operator];
            if (currentAllowance < _amount) {
                revert Errors.Insufficient(currentAllowance, _amount);
            }
            _vault.allowances[_sender][_operator] = currentAllowance - _amount;
        }

        transfer(_vault, _rs, _sender, _recipient, _amount);
    }

    function transfer(
        ALMVault storage _vault,
        Restrictions storage _rs,
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_sender == address(0) || _recipient == address(0)) revert Errors.ZeroAddress();
        if (_amount == 0) revert Errors.ZeroValue();
        AC.checkAlmMinterUnrestricted(_rs, _vault.id, _recipient);

        if (_vault.balances[_sender] < _amount) {
            revert Errors.Insufficient(_vault.balances[_sender], _amount);
        }

        _vault.balances[_sender] -= _amount;
        _vault.balances[_recipient] += _amount;

        emit Events.Transfer(_sender, _recipient, _amount);
    }

    function mint(ALMVault storage _vault, Restrictions storage _rs, address _account, uint256 _amount) internal {
        if (_account == address(0)) revert Errors.ZeroAddress();
        AC.checkAlmMinterUnrestricted(_rs, _vault.id, _account);
        if (_vault.maxSupply > 0 && _vault.totalSupply + _amount > _vault.maxSupply) {
            revert Errors.Exceeds(_vault.totalSupply + _amount, _vault.maxSupply);
        }
        _vault.totalSupply += _amount;
        _vault.balances[_account] += _amount;
        emit Events.Transfer(address(0), _account, _amount);
    }

    function burn(ALMVault storage _vault, Restrictions storage _rs, address _account, uint256 _amount) internal {
        if (_account == address(0)) revert Errors.ZeroAddress();
        AC.checkAlmMinterUnrestricted(_rs, _vault.id, _account);
        if (_vault.balances[_account] < _amount) {
            revert Errors.Insufficient(_vault.balances[_account], _amount);
        }
        _vault.totalSupply -= _amount;
        _vault.balances[_account] -= _amount;
        emit Events.Transfer(_account, address(0), _amount);
    }
}
