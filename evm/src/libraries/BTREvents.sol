// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@/BTRTypes.sol";
import {IDiamondCut} from "@interfaces/IDiamond.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title BTR Events Library - Centralized event definitions
 * @copyright 2025
 * @notice Defines all custom events emitted by the BTR protocol contracts
 * @dev Used for consistency and off-chain indexing
 * @author BTR Team
 */

library BTRErrors {
    error ZeroValue();
    error ZeroAddress();
    error InvalidParameter();
    error NotFound(ErrorType _errorType);
    error Unauthorized(ErrorType _errorOrigin);
    error AlreadyExists(ErrorType _errorType);
    error Insufficient(uint256 _actual, uint256 _minimum);
    error Exceeds(uint256 _actual, uint256 _maximum);
    error OutOfRange(uint256 _actual, uint256 _minimum, uint256 _maximum);
    error NotInitialized();
    error AlreadyInitialized();
    error InitializationFailed();
    error Failed(ErrorType _errorType);
    error Paused(ErrorType _errorType);
    error NotPaused(ErrorType _errorType);
    error Locked();
    error Expired(ErrorType _errorType);
    error NotZero(uint256 _nonZeroValue);
    error WrongOrder(ErrorType _errorType);
    error UnexpectedInput();
    error UnexpectedOutput();
    error RouterError();
    error DelegateCallFailed();
    error StaticCallFailed();
    error SlippageTooHigh();
    error StalePrice();
}

library BTREvents {
    // ERC1155/ERC20 events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event Deposit(address indexed _caller, address indexed _owner, uint256 _assets, uint256 _shares);
    event Withdraw(
        address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares
    );
    event MaxSupplyUpdated(uint32 indexed _vid, uint256 _newCapacity);
    // ERC-2535/Diamond events
    event VersionUpdated(uint8 _version);
    event FunctionAdded(address indexed _facetAddress, bytes4 _selector);
    event FunctionReplaced(address indexed _oldFacetAddress, address indexed _newFacetAddress, bytes4 _selector);
    event FunctionRemoved(address indexed _facetAddress, bytes4 _selector);
    event FacetAdded(address indexed _facetAddress);
    event FacetRemoved(address indexed _facetAddress);
    event InitializationFailed(address indexed _initContract, bytes _reason);
    // AccessControl events
    event RoleGranted(bytes32 indexed _role, address indexed _account, address indexed _sender);
    event RoleRevoked(bytes32 indexed _role, address indexed _account, address indexed _sender);
    event RoleAcceptanceCreated(bytes32 indexed _role, address indexed _account, address indexed _sender);
    event RoleAdminUpdated(bytes32 indexed _role, bytes32 indexed _previousAdminRole, bytes32 indexed _newAdminRole);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event TimelockConfigUpdated(uint256 _grantDelay, uint256 _acceptanceTtl);
    // Rescue events
    event RescueConfigUpdated(uint64 _timelock, uint64 _validity);
    event RescueRequested(address indexed _receiver, uint64 _timestamp, TokenType _tokenType, bytes32[] _tokens);
    event RescueExecuted(address indexed _token, address indexed _receiver, uint256 _amount, TokenType _tokenType);
    event RescueCancelled(address indexed _receiver, TokenType _tokenType, bytes32[] _tokens);
    event TokenRescued(address indexed _token, uint256 indexed _tokenId, address indexed _receiver);
    event RescueFailed(address indexed _token, uint256 _tokenId, string _reason);
    // Oracle events
    event DataFeedUpdated(bytes32 indexed _feed, address indexed _provider, bytes32 indexed _providerId, uint256 _ttl);
    event DataFeedRemoved(bytes32 indexed _feed, address indexed _provider);
    event DataProviderUpdated(address indexed _oldProvider, address indexed _newProvider);
    event DataProviderRemoved(address indexed _provider);
    event TwapLookbackUpdated(bytes32 indexed _feed, uint32 _lookback);
    event MaxDeviationUpdated(bytes32 indexed _feed, uint256 _maxDeviationBp);
    // ALM events
    event VaultCreated(uint32 indexed _vid, address indexed _creator, VaultInitParams _params);
    event VaultRebalanced(uint32 indexed _vid, uint256 _in0, uint256 _in1, uint256 _fee0, uint256 _fee1);
    event PoolUpdated(bytes32 indexed _pid, address _adapter, address _token0, address _token1);
    event PoolRemoved(bytes32 indexed _pid);
    event DEXAdapterUpdated(address indexed _old, address indexed _new, uint256 _count);
    event DEXAdapterRemoved(address indexed _adapter);
    event SharesMinted(
        address indexed _payer,
        address indexed _receiver,
        uint256 _mintedShares,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _fee0,
        uint256 _fee1
    );
    event SharesBurnt(
        address indexed _payer,
        address indexed _receiver,
        uint256 _burntShares,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _fee0,
        uint256 _fee1
    );
    event RangeMinted(bytes32 indexed _rid, uint256 _liquidity, uint256 _amount0, uint256 _amount1);
    event RangeBurnt(
        bytes32 indexed _rid, uint256 _liquidity, uint256 _burn0, uint256 _burn1, uint256 _fee0, uint256 _fee1
    );
    // Treasury events
    event TreasuryUpdated(address indexed _treasury);
    event FeesUpdated(uint32 indexed _vid, uint16 _entry, uint16 _exit, uint16 _mgmt, uint16 _perf, uint16 _flash);
    event CustomFeesUpdated(
        address indexed _user, uint16 _entry, uint16 _exit, uint16 _mgmt, uint16 _perf, uint16 _flash
    );
    event ALMFeesAccrued(
        uint32 indexed _vid,
        address indexed _token0,
        address indexed _token1,
        uint256 _perfFee0,
        uint256 _perfFee1,
        uint256 _mgmtFee0,
        uint256 _mgmtFee1
    );
    event ALMFeesCollected(
        uint32 indexed _vid, address indexed _token0, address indexed _token1, uint256 _fee0, uint256 _fee1, address _by
    );
    // Swap events
    event RouterAdded(address indexed _router);
    event RouterRemoved(address indexed _router);
    event Swapped(
        address indexed _user,
        address indexed _assetIn,
        address indexed _assetOut,
        uint256 _amountIn,
        uint256 _amountOut
    );
    // Management events
    event Paused(uint32 indexed _vid, address indexed _by);
    event Unpaused(uint32 indexed _vid, address indexed _by);
    event MintRestricted(uint32 indexed _vid, address _by);
    event MintUnrestricted(uint32 indexed _vid, address _by);
    event RestrictionUpdated(uint8 indexed _restrictionType, bool _enabled);
    event AccountStatusUpdated(address indexed _account, AccountStatus _previousStatus, AccountStatus _newStatus);
    // Risk management events
    event RiskModelUpdated(RiskModel _oldModel, RiskModel _newModel);
    event WeightModelUpdated(WeightModel _oldModel, WeightModel _newModel);
    event LiquidityModelUpdated(LiquidityModel _oldModel, LiquidityModel _newModel);
    event SlippageModelUpdated(SlippageModel _oldModel, SlippageModel _newModel);
    event PoolCScoreUpdated(bytes32 indexed _poolId, uint16 _oldScore, uint16 _newScore);
    // Price protection/Oracle events
    event DefaultPriceProtectionUpdated(uint32 _lookback, uint256 _maxDeviation);
    event VaultPriceProtectionUpdated(uint32 indexed _vid, uint32 _lookback, uint256 _maxDeviation);
}
