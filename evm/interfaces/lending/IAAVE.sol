// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseAsset;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

interface IAaveV3Pool {
    // Events
    event MintUnbacked(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens
    );

    event SwapBorrowRateMode(
        address indexed reserve, address indexed user, DataTypes.InterestRateMode interestRateMode
    );

    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    event UserEModeSet(address indexed user, uint8 categoryId);

    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    // Functions
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function backUnbacked(address asset, uint256 amount, uint256 fee) external;

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;

    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);

    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    function rebalanceStableBorrowRate(address asset, address user) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function dropReserve(address asset) external;

    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getReserveAddressById(uint16 id) external view returns (address);

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    function setUserEMode(uint8 categoryId) external;

    function getUserEMode(address user) external view returns (uint256);

    function resetIsolationModeTotalDebt(address asset) external;

    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    function MAX_NUMBER_RESERVES() external view returns (uint16);

    function mintToTreasury(address[] calldata assets) external;

    function rescueTokens(address token, address to, uint256 amount) external;

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

interface IRewardsController {
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function POOL() external view returns (IAaveV3Pool);
}

interface IFlashLoanSimpleReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bool);

    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function POOL() external view returns (IAaveV3Pool);
}

interface IPoolAddressesProvider {
    // Events
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    // Functions
    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata newMarketId) external;

    function getAddress(bytes32 id) external view returns (address);

    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    function setAddress(bytes32 id, address newAddress) external;

    function getPool() external view returns (address);

    function setPoolImpl(address newPoolImpl) external;

    function getPoolConfigurator() external view returns (address);

    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address newPriceOracle) external;

    function getACLManager() external view returns (address);

    function setACLManager(address newAclManager) external;

    function getACLAdmin() external view returns (address);

    function setACLAdmin(address newAclAdmin) external;

    function getPriceOracleSentinel() external view returns (address);

    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    function getPoolDataProvider() external view returns (address);

    function setPoolDataProvider(address newDataProvider) external;
}

interface IPriceOracleGetter {
    // Functions
    function BASE_CURRENCY() external view returns (address);

    function BASE_CURRENCY_UNIT() external view returns (uint256);

    function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveOracle is IPriceOracleGetter {
    // Events
    event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

    event AssetSourceUpdated(address indexed asset, address indexed source);

    event FallbackOracleUpdated(address indexed fallbackOracle);

    // Functions
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    function setFallbackOracle(address fallbackOracle) external;

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    function getSourceOfAsset(address asset) external view returns (address);

    function getFallbackOracle() external view returns (address);
}
