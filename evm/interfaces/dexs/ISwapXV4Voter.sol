// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapXV4Voter {
    function MAX_VOTE_DELAY() external view returns (uint256);
    function VOTE_DELAY() external view returns (uint256);
    function _epochTimestamp() external view returns (uint256);
    function _init(address _permissionsRegistry, address _minter) external;
    function _ve() external view returns (address);
    function addFactory(address _pairFactory, address _gaugeFactory) external;
    function bribefactory() external view returns (address);
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;
    function claimBribes(address[] memory _bribes, address[][] memory _tokens) external;
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external;
    function claimFees(address[] memory _bribes, address[][] memory _tokens) external;
    function claimRewards(address[] memory _gauges) external;
    function claimable(address) external view returns (uint256);
    function createGauge(address _pool, uint256 _gaugeType)
        external
        returns (address _gauge, address _internal_bribe, address _external_bribe);
    function createGauges(address[] memory _pool, uint256[] memory _gaugeTypes)
        external
        returns (address[] memory, address[] memory, address[] memory);
    function distribute(address[] memory _gauges) external;
    function distribute(uint256 start, uint256 finish) external;
    function distributeAll() external;
    function distributeFees(address[] memory _gauges) external;
    function external_bribes(address) external view returns (address);
    function factories() external view returns (address[] memory);
    function factory() external view returns (address);
    function factoryLength() external view returns (uint256);
    function gaugeFactories() external view returns (address[] memory);
    function gaugeFactoriesLength() external view returns (uint256);
    function gauges(address) external view returns (address);
    function gaugesDistributionTimestmap(address) external view returns (uint256);
    function hasGaugeKilled(address) external view returns (uint256);
    function indexAt(uint256 _time) external view returns (uint256);
    function initialize(address __ve, address _pairFactory, address _gaugeFactory, address _bribes, address _masterChef)
        external;
    function internal_bribes(address) external view returns (address);
    function isAlive(address) external view returns (bool);
    function isFactory(address) external view returns (bool);
    function isGauge(address) external view returns (bool);
    function isGaugeFactory(address) external view returns (bool);
    function killGauge(address _gauge) external;
    function lastVoted(uint256) external view returns (uint256);
    function length() external view returns (uint256);
    function masterChef() external view returns (address);
    function minter() external view returns (address);
    function notifyRewardAmount(uint256 amount) external;
    function owner() external view returns (address);
    function permissionRegistry() external view returns (address);
    function poke(uint256 _tokenId) external;
    function poolForGauge(address) external view returns (address);
    function poolVote(uint256, uint256) external view returns (address);
    function poolVoteLength(uint256 tokenId) external view returns (uint256);
    function pools(uint256) external view returns (address);
    function recoverERC20(address token, uint256 amount) external;
    function removeFactory(uint256 _pos) external;
    function renounceOwnership() external;
    function replaceFactory(address _pairFactory, address _gaugeFactory, uint256 _pos) external;
    function reset(uint256 _tokenId) external;
    function reviveGauge(address _gauge) external;
    function setBribeFactory(address _bribeFactory) external;
    function setExternalBribeFor(address _gauge, address _external) external;
    function setInternalBribeFor(address _gauge, address _internal) external;
    function setMinter(address _minter) external;
    function setNewBribes(address _gauge, address _internal, address _external) external;
    function setPairFactory(address _factory) external;
    function setPermissionsRegistry(address _permissionRegistry) external;
    function setVoteDelay(uint256 _delay) external;
    function totalWeight() external view returns (uint256);
    function totalWeightAt(uint256 _time) external view returns (uint256);
    function transferOwnership(address newOwner) external;
    function vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights) external;
    function votes(uint256, address) external view returns (uint256);
    function weights(address _pool) external view returns (uint256);
    function weightsAt(address _pool, uint256 _time) external view returns (uint256);
}
