// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {BTRErrors as Errors, BTREvents as Events} from "@libraries/BTREvents.sol";
import {ErrorType, TokenType, Rescue, RescueRequest} from "@/BTRTypes.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibAccessControl as AC} from "@libraries/LibAccessControl.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Rescue Library - Asset rescue logic
 * @copyright 2025
 * @notice Contains internal functions for the asset rescue mechanism
 * @dev Helper library for RescueFacet
 * @author BTR Team
 */

library LibRescue {
    using SafeERC20 for IERC20;
    // --- CONSTANTS ---

    uint64 public constant DEFAULT_RESCUE_TIMELOCK = 2 days;
    uint64 public constant DEFAULT_RESCUE_VALIDITY = 7 days;
    uint64 public constant MIN_RESCUE_TIMELOCK = 1 days;
    uint64 public constant MAX_RESCUE_TIMELOCK = 7 days;
    uint64 public constant MIN_RESCUE_VALIDITY = 1 days;
    uint64 public constant MAX_RESCUE_VALIDITY = 30 days;
    address internal constant ETH_ADDRESS = address(1); // Special token address for native ETH

    // --- INITIALIZATION ---

    function initialize(Rescue storage _res) internal {
        _res.rescueTimelock = DEFAULT_RESCUE_TIMELOCK;
        _res.rescueValidity = DEFAULT_RESCUE_VALIDITY;
    }

    // --- VIEWS ---

    function getRescueRequest(Rescue storage _res, address _receiver, TokenType _tokenType)
        internal
        view
        returns (RescueRequest storage)
    {
        return _res.rescueRequests[_receiver][_tokenType];
    }

    function rescueStatus(Rescue storage _res, address _receiver, TokenType _tokenType) internal view returns (uint8) {
        RescueRequest storage request = getRescueRequest(_res, _receiver, _tokenType);
        if (request.timestamp == 0) return 0; // No request

        uint64 timelock = _res.rescueTimelock;
        uint64 validity = _res.rescueValidity;

        uint64 unlockTime = request.timestamp + timelock;
        uint64 expiryTime = unlockTime + validity;

        uint64 currentTime = uint64(block.timestamp);
        if (currentTime < unlockTime) return 1; // Locked
        if (currentTime >= expiryTime) return 3; // Expired
        return 2; // Unlocked and valid
    }

    function isRescueLocked(Rescue storage _res, address _receiver, TokenType _tokenType)
        internal
        view
        returns (bool)
    {
        return rescueStatus(_res, _receiver, _tokenType) == 1;
    }

    function isRescueExpired(Rescue storage _res, address _receiver, TokenType _tokenType)
        internal
        view
        returns (bool)
    {
        return rescueStatus(_res, _receiver, _tokenType) == 3;
    }

    function isRescueUnlocked(Rescue storage _res, address _receiver, TokenType _tokenType)
        internal
        view
        returns (bool)
    {
        return rescueStatus(_res, _receiver, _tokenType) == 2;
    }

    // --- CONFIGURATION ---

    function setRescueConfig(Rescue storage _res, uint64 _timelock, uint64 _validity) internal {
        if (
            _timelock < MIN_RESCUE_TIMELOCK || _timelock > MAX_RESCUE_TIMELOCK || _validity < MIN_RESCUE_VALIDITY
                || _validity > MAX_RESCUE_VALIDITY
        ) {
            revert Errors.OutOfRange(_timelock, MIN_RESCUE_TIMELOCK, MAX_RESCUE_TIMELOCK);
        }

        _res.rescueTimelock = _timelock;
        _res.rescueValidity = _validity;

        emit Events.RescueConfigUpdated(_timelock, _validity);
    }

    // --- RESCUE REQUESTS ---

    function createRescueRequest(
        Rescue storage _res,
        address _receiver,
        TokenType _tokenType,
        address _tokenAddress,
        bytes32[] memory _tokenIds
    ) private {
        RescueRequest storage request = getRescueRequest(_res, _receiver, _tokenType);

        // Create the rescue request
        request.timestamp = uint64(block.timestamp);
        request.receiver = _receiver;
        request.tokenType = _tokenType;
        request.tokenAddress = _tokenAddress;

        // Store the token IDs
        delete request.tokenIds;

        // Copy _tokenIds to storage - use unchecked to save gas on loop counters
        uint256 length = _tokenIds.length;
        if (length > 0) {
            // Pre-allocate the array size to save gas
            request.tokenIds = new bytes32[](length);

            unchecked {
                for (uint256 i = 0; i < length; ++i) {
                    request.tokenIds[i] = _tokenIds[i];
                }
            }
        }

        emit Events.RescueRequested(_receiver, uint64(block.timestamp), _tokenType, request.tokenIds);
    }

    function requestRescueNative(Rescue storage _res) internal {
        createRescueRequest(_res, msg.sender, TokenType.NATIVE, ETH_ADDRESS, new bytes32[](0));
    }

    function requestRescueERC20(Rescue storage _res, address[] memory _tokenAddresses) internal {
        // Store all token addresses as bytes32 in _tokenIds
        uint256 length = _tokenAddresses.length;
        bytes32[] memory encodedAddresses = new bytes32[](length);

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                encodedAddresses[i] = bytes32(uint256(uint160(_tokenAddresses[i])));
            }
        }

        // Create a single request with multiple tokens
        createRescueRequest(_res, msg.sender, TokenType.ERC20, address(0), encodedAddresses);
    }

    function requestRescueERC721(Rescue storage _res, address _tokenAddress, uint256 _tokenId) internal {
        bytes32[] memory tokenIds = new bytes32[](1);
        tokenIds[0] = bytes32(_tokenId);
        createRescueRequest(_res, msg.sender, TokenType.ERC721, _tokenAddress, tokenIds);
    }

    function requestRescueERC721(Rescue storage _res, address _tokenAddress, bytes32[] memory _tokenIds) internal {
        createRescueRequest(_res, msg.sender, TokenType.ERC721, _tokenAddress, _tokenIds);
    }

    function requestRescueERC1155(Rescue storage _res, address _tokenAddress, uint256 _tokenId) internal {
        bytes32[] memory tokenIds = new bytes32[](1);
        tokenIds[0] = bytes32(_tokenId);
        createRescueRequest(_res, msg.sender, TokenType.ERC1155, _tokenAddress, tokenIds);
    }

    function requestRescueERC1155(Rescue storage _res, address _tokenAddress, bytes32[] memory _tokenIds) internal {
        createRescueRequest(_res, msg.sender, TokenType.ERC1155, _tokenAddress, _tokenIds);
    }

    function cancelRescue(Rescue storage _res, address _receiver, TokenType _tokenType) internal {
        RescueRequest storage request = getRescueRequest(_res, _receiver, _tokenType);

        // Create copies for the event
        // address tokenAddress = request.tokenAddress;
        uint256 length = request.tokenIds.length;
        bytes32[] memory tokenIdsCopy = new bytes32[](length);

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tokenIdsCopy[i] = request.tokenIds[i];
            }
        }

        // Clear the rescue request
        delete _res.rescueRequests[_receiver][_tokenType];

        emit Events.RescueCancelled(_receiver, _tokenType, tokenIdsCopy);
    }

    function cancelRescueAll(Rescue storage _res, address _receiver) internal {
        cancelRescue(_res, _receiver, TokenType.NATIVE);
        cancelRescue(_res, _receiver, TokenType.ERC20);
        cancelRescue(_res, _receiver, TokenType.ERC721);
        cancelRescue(_res, _receiver, TokenType.ERC1155);
    }

    // --- EXECUTE RESCUE ---

    function validateRescue(Rescue storage _res, address _receiver, TokenType _tokenType) internal view {
        uint8 status = rescueStatus(_res, _receiver, _tokenType);

        if (status == 0) {
            revert Errors.NotFound(ErrorType.RESCUE);
        } else if (status == 1) {
            revert Errors.Locked();
        } else if (status == 3) {
            revert Errors.Expired(ErrorType.RESCUE);
        }
        // Status must be 2 (unlocked) to proceed
    }

    function rescueTokenType(Rescue storage _res, address _receiver, TokenType _tokenType, bool _validate)
        private
        returns (bool)
    {
        // Check status only if requested (optimized path for rescueAll)
        if (_validate) {
            uint8 status = rescueStatus(_res, _receiver, _tokenType);
            if (status != 2) return false; // Only proceed if unlocked
        }

        // Get request data (once) and cache in memory
        RescueRequest storage request = getRescueRequest(_res, _receiver, _tokenType);
        // address tokenAddress = request.tokenAddress;
        uint256 tokenIdsLength = request.tokenIds.length;
        bool success = false;

        if (_tokenType == TokenType.NATIVE) {
            // Rescue ETH
            uint256 balance = address(this).balance;
            if (balance > 0) {
                (bool sent,) = _receiver.call{value: balance}("");
                if (sent) {
                    emit Events.RescueExecuted(ETH_ADDRESS, _receiver, balance, TokenType.NATIVE);
                    success = true;
                }
            }
        } else if (_tokenType == TokenType.ERC20) {
            // Rescue ERC20 tokens
            if (tokenIdsLength > 0) {
                // Multiple ERC20 tokens stored in tokenIds
                unchecked {
                    for (uint256 i = 0; i < tokenIdsLength; ++i) {
                        bytes32 tokenIdData = request.tokenIds[i];
                        address erc20Address = address(uint160(uint256(tokenIdData)));
                        if (erc20Address != address(0)) {
                            IERC20 token = IERC20(erc20Address);
                            uint256 balance = token.balanceOf(address(this));
                            if (balance > 0) {
                                IERC20(erc20Address).safeTransfer(_receiver, balance);
                                emit Events.RescueExecuted(erc20Address, _receiver, balance, TokenType.ERC20);
                                success = true;
                            }
                        }
                    }
                }
            } else if (request.tokenAddress != address(0)) {
                // Single ERC20 token in tokenAddress
                IERC20 token = IERC20(request.tokenAddress);
                uint256 balance = token.balanceOf(address(this));
                if (balance > 0) {
                    token.safeTransfer(_receiver, balance);
                    emit Events.RescueExecuted(request.tokenAddress, _receiver, balance, TokenType.ERC20);
                    success = true;
                }
            }
        } else if (_tokenType == TokenType.ERC721) {
            // Rescue ERC721 tokens
            if (request.tokenAddress != address(0) && tokenIdsLength > 0) {
                IERC721 nft = IERC721(request.tokenAddress);
                unchecked {
                    for (uint256 i = 0; i < tokenIdsLength; ++i) {
                        uint256 tokenId = uint256(request.tokenIds[i]);
                        nft.safeTransferFrom(address(this), _receiver, tokenId);
                        emit Events.RescueExecuted(request.tokenAddress, _receiver, tokenId, TokenType.ERC721);
                        success = true;
                    }
                }
            }
        } else if (_tokenType == TokenType.ERC1155) {
            // Rescue ERC1155 tokens
            if (request.tokenAddress != address(0) && tokenIdsLength > 0) {
                IERC1155 token = IERC1155(request.tokenAddress);
                unchecked {
                    for (uint256 i = 0; i < tokenIdsLength; ++i) {
                        uint256 tokenId = uint256(request.tokenIds[i]);
                        uint256 balance = token.balanceOf(address(this), tokenId);
                        if (balance > 0) {
                            token.safeTransferFrom(address(this), _receiver, tokenId, balance, "");
                            emit Events.RescueExecuted(request.tokenAddress, _receiver, tokenId, TokenType.ERC1155);
                            success = true;
                        }
                    }
                }
            }
        }

        // Clear the rescue request if any rescue was successful or we're validating
        if (success || _validate) {
            delete _res.rescueRequests[_receiver][_tokenType];
        }

        return success;
    }

    function rescueAll(Rescue storage _res, address _receiver) internal {
        // Only attempt rescues for requests that exist and are unlocked
        // This avoids unnecessary gas consumption
        uint8 nativeStatus = rescueStatus(_res, _receiver, TokenType.NATIVE);
        uint8 erc20Status = rescueStatus(_res, _receiver, TokenType.ERC20);
        uint8 erc721Status = rescueStatus(_res, _receiver, TokenType.ERC721);
        uint8 erc1155Status = rescueStatus(_res, _receiver, TokenType.ERC1155);

        if (nativeStatus == 2) rescueTokenType(_res, _receiver, TokenType.NATIVE, false);
        if (erc20Status == 2) rescueTokenType(_res, _receiver, TokenType.ERC20, false);
        if (erc721Status == 2) rescueTokenType(_res, _receiver, TokenType.ERC721, false);
        if (erc1155Status == 2) rescueTokenType(_res, _receiver, TokenType.ERC1155, false);
    }

    function rescue(Rescue storage _res, address _receiver, TokenType _tokenType) internal {
        validateRescue(_res, _receiver, _tokenType);
        bool success = rescueTokenType(_res, _receiver, _tokenType, false);
        if (!success) {
            // Clear the request even if rescue failed - it was validated
            delete _res.rescueRequests[_receiver][_tokenType];
        }
    }
}
