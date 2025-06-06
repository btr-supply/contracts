// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IRamsesV3Voter {
    function BASIS() external view returns (uint256);
    function accessHub() external view returns (address);
    function batchDistribute(address[] calldata _gauges) external;
    function batchDistributeByIndex(uint256 startIndex, uint256 endIndex) external;
    function batchDistributeByIndexNoPush(uint256 startIndex, uint256 endIndex) external;
    function clFactory() external view returns (address);
    function clGaugeFactory() external view returns (address);
    function claimClGaugeRewards(
        address[] calldata _gauges,
        address[][] calldata _tokens,
        uint256[][] calldata _nfpTokenIds
    ) external;
    function claimIncentives(uint256 tokenId, address[] calldata _feeDistributors, address[][] calldata _tokens)
        external;
    function claimLegacyRewardsAndExit(address[] calldata _gauges, address[][] calldata _tokens) external;
    function claimRewards(address[] calldata _gauges, address[][] calldata _tokens) external;
    function createArbitraryGauge(address _token) external returns (address _arbitraryGauge);
    function createCLGauge(address tokenA, address tokenB, int24 tickSpacing) external returns (address _clGauge);
    function createGauge(address _pool) external returns (address _gauge);
    function distribute(address _gauge) external;
    function distributeAll() external;
    function distributeForPeriod(address _gauge, uint256 _period) external;
    function emissionsToken() external view returns (address _emissionsToken);
    function feeDistributorFactory() external view returns (address _feeDistributorFactory);
    function feeDistributorForGauge(address _gauge) external view returns (address _feeDistributor);
    function feeRecipientFactory() external view returns (address);
    function forbid(address _token) external;
    function gaugeForClPool(address tokenA, address tokenB, int24 tickSpacing) external view returns (address gauge);
    function gaugeForLegacyPool(address tokenA, address tokenB, bool stable) external view returns (address _gauge);
    function gaugeForPool(address _pool) external view returns (address _gauge);
    function gaugefactory() external view returns (address _gaugeFactory);
    function getAllCustomPools() external view returns (address[] memory _customPools);
    function getAllFeeDistributorst() external view returns (address[] memory _feeDistributors);
    function getAllGauges() external view returns (address[] memory _gauges);
    function getAllPools() external view returns (address[] memory _pools);
    function getPeriod() external view returns (uint256 period);
    function getVotes(uint256 tokenId) external view returns (address[] memory votes, uint256[] memory weights);
    function governor() external view returns (address _governor);
    function initialize(
        address _emissionsToken,
        address _legacyFactory,
        address _gauges,
        address _feeDistributorFactory,
        address _minter,
        address _msig,
        address _ve,
        address _clFactory,
        address _clGaugeFactory,
        address _nfpManager,
        address _feeRecipientFactory,
        address _voteModule,
        address _launcherPlugin
    ) external;
    function isAlive(address _gauge) external view returns (bool _trueOrFalse);
    function isFeeDistributor(address _feeDistributor) external view returns (bool _trueOrFalse);
    function isGauge(address gauge) external view returns (bool _trueOrFalse);
    function isWhitelisted(address _token) external view returns (bool _tf);
    function killGauge(address _gauge) external;
    function launcherPlugin() external view returns (address _launcherPlugin);
    function legacyFactory() external view returns (address);
    function mainCurveForPair(address tokenA, address tokenB) external view returns (bool _trueOrFalse);
    function mainTickSpacingForPair(address tokenA, address tokenB) external view returns (int24 _ts);
    function minter() external view returns (address _minter);
    function nfpManager() external view returns (address);
    function notifyRewardAmount(uint256 amount) external;
    function poke(uint256 tokenId) external;
    function poolRedirect(address fromPool) external view returns (address toPool);
    function removeFeeDistributorReward(address _feeDist, address _token) external;
    function removeGaugeRewardWhitelist(address _gauge, address _reward) external;
    function reset(uint256 tokenId) external;
    function reviveGauge(address _gauge) external;
    function revokeWhitelist(address _token) external;
    function setGlobalRatio(uint256 _xRatio) external;
    function setGovernor(address _governor) external;
    function setMainCurve(address tokenA, address tokenB, bool stable) external;
    function setMainTickSpacing(address tokenA, address tokenB, int24 tickSpacing) external;
    function stuckEmissionsRecovery(address _gauge, uint256 _period) external;
    function tickSpacingsForPair(address tokenA, address tokenB) external view returns (int24[] memory _ts);
    function tokenIdVotingPowerPerPeriod(uint256 tokenId, uint256 period)
        external
        view
        returns (uint256 tokenIdVotingPowerPerPeriod);
    function vote(uint256 tokenId, address[] calldata _pools, uint256[] calldata _weights) external;
    function voteModule() external view returns (address _voteModule);
    function votingEscrow() external view returns (address ve);
    function whitelist(address _token) external;
    function whitelistGaugeRewards(address _gauge, address _reward) external;
    function xRatio() external view returns (uint256);
}
