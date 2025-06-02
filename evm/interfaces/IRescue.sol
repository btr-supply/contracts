// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {TokenType} from "@/BTRTypes.sol";

interface IRescueFacet {
    function initializeRescue() external;
    function rescueStatus(address _receiver, TokenType _tokenType) external view returns (uint8);
    function isRescueLocked(address _receiver, TokenType _tokenType) external view returns (bool);
    function isRescueExpired(address _receiver, TokenType _tokenType) external view returns (bool);
    function isRescueUnlocked(address _receiver, TokenType _tokenType) external view returns (bool);
    function getRescueConfig() external view returns (uint64 _timelock, uint64 _validity);
    function requestRescueNative() external;
    function requestRescueERC20(address[] calldata _tokens) external;
    function requestRescueERC721(address _tokenAddress, uint256 _tokenId) external;
    function requestRescueERC1155(address _tokenAddress, uint256 _tokenId) external;
    function rescue(address _receiver, TokenType _tokenType) external;
    function rescueAll(address _receiver) external;
    function cancelRescue(address _receiver, TokenType _tokenType) external;
    function cancelRescueAll(address _receiver) external;
    function setRescueConfig(uint64 _timelock, uint64 _validity) external;
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool);
}
