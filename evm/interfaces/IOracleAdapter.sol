// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IOracleAdapter {
    // --- FEED DETECTION ---
    function hasFeed(bytes32 _feed) external view returns (bool);
    // --- FEED MANAGEMENT ---
    function setFeed(bytes32 _feed, bytes32 _providerId, uint256 _validity) external;
    function removeFeed(bytes32 _feed) external;
    function setFeeds(bytes32[] memory _feeds, bytes32[] memory _providerIds, uint256[] memory _validities) external;
    function update(bytes calldata _params) external;
    function setAlt(address _altProvider) external;

    function removeAlt() external;
}
