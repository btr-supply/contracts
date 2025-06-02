// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {TokenType, ErrorType, Rescue, RescueRequest} from "@/BTRTypes.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {BTRStorage as S} from "@libraries/BTRStorage.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {LibRescue as R} from "@libraries/LibRescue.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {PermissionedFacet} from "@facets/abstract/PermissionedFacet.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Asset Rescue - Emergency asset recovery
 * @copyright 2025
 * @notice Allows recovery of stuck/lost assets in emergency situations
 * @dev Emergency function to recover ERC20/721/1155/Native tokens sent directly to the diamond address
- Security Critical: Direct access to contract balances. Uses a request -> execute pattern with timelock
- Modifiers: `requestRescue*` use `onlyAdmin`, `rescue` uses `onlyManager`. Check `LibRescue` for timelock logic

 * @author BTR Team
 */

contract RescueFacet is PermissionedFacet, IERC721Receiver, IERC1155Receiver {
    // --- INITIALIZATION ---

    function initializeRescue() external onlyAdmin {
        R.initialize(S.res());
    }

    // --- VIEWS ---

    function getRescueRequest(address _receiver, TokenType _tokenType)
        external
        view
        returns (uint64 _timestamp, address _tokenAddress, uint256 _tokenIdsCount)
    {
        RescueRequest storage request = R.getRescueRequest(S.res(), _receiver, _tokenType);
        return (request.timestamp, request.tokenAddress, request.tokenIds.length);
    }

    function rescueStatus(address _receiver, TokenType _tokenType) external view returns (uint8) {
        return R.rescueStatus(S.res(), _receiver, _tokenType);
    }

    function isRescueLocked(address _receiver, TokenType _tokenType) external view returns (bool) {
        return R.isRescueLocked(S.res(), _receiver, _tokenType);
    }

    function isRescueExpired(address _receiver, TokenType _tokenType) external view returns (bool) {
        return R.isRescueExpired(S.res(), _receiver, _tokenType);
    }

    function isRescueUnlocked(address _receiver, TokenType _tokenType) external view returns (bool) {
        return R.isRescueUnlocked(S.res(), _receiver, _tokenType);
    }

    function getRescueConfig() external view returns (uint64 _timelock, uint64 _validity) {
        Rescue storage rs = S.res();
        return (rs.rescueTimelock, rs.rescueValidity);
    }

    // --- RESCUE REQUESTS ---

    function requestRescueNative() external onlyAdmin {
        R.requestRescueNative(S.res());
    }

    function requestRescueERC20(address[] calldata _tokens) external onlyAdmin {
        if (_tokens.length == 0) revert Errors.InvalidParameter();
        R.requestRescueERC20(S.res(), _tokens);
    }

    function requestRescueERC721(address _tokenAddress, uint256 _tokenId) external onlyAdmin {
        R.requestRescueERC721(S.res(), _tokenAddress, _tokenId);
    }

    function requestRescueERC721Batch(address _tokenAddress, uint256[] calldata _tokenIds) external onlyAdmin {
        bytes32[] memory ids = new bytes32[](_tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                ids[i] = bytes32(_tokenIds[i]);
            }
        }
        R.requestRescueERC721(S.res(), _tokenAddress, ids);
    }

    function requestRescueERC1155(address _tokenAddress, uint256 _tokenId) external onlyAdmin {
        R.requestRescueERC1155(S.res(), _tokenAddress, _tokenId);
    }

    function requestRescueERC1155Batch(address _tokenAddress, uint256[] calldata _tokenIds) external onlyAdmin {
        bytes32[] memory ids = new bytes32[](_tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                ids[i] = bytes32(_tokenIds[i]);
            }
        }
        R.requestRescueERC1155(S.res(), _tokenAddress, ids);
    }

    function rescue(address _receiver, TokenType _tokenType) external onlyManager {
        R.rescue(S.res(), _receiver, _tokenType);
    }

    function rescueAll(address _receiver) external onlyManager {
        R.rescueAll(S.res(), _receiver);
    }

    function cancelRescue(address _receiver, TokenType _tokenType) external {
        // Verify that msg.sender is either the receiver or an admin
        if (msg.sender != _receiver && !AC.hasRole(S.acc(), AC.ADMIN_ROLE, msg.sender)) {
            revert Errors.Unauthorized(ErrorType.RESCUE);
        }
        R.cancelRescue(S.res(), _receiver, _tokenType);
    }

    function cancelRescueAll(address _receiver) external {
        // Verify that msg.sender is either the receiver or an admin
        if (msg.sender != _receiver && !AC.hasRole(S.acc(), AC.ADMIN_ROLE, msg.sender)) {
            revert Errors.Unauthorized(ErrorType.RESCUE);
        }
        R.cancelRescueAll(S.res(), _receiver);
    }

    // --- CONFIGURATION ---

    function setRescueConfig(uint64 _timelock, uint64 _validity) external onlyAdmin {
        R.setRescueConfig(S.res(), _timelock, _validity);
    }

    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return _interfaceId == type(IERC721Receiver).interfaceId || _interfaceId == type(IERC1155Receiver).interfaceId
            || _interfaceId == type(IERC165).interfaceId;
    }

    // --- RECEIVER INTERFACES ---

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
