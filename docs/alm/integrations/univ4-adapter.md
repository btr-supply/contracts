# Uniswap V4 Implementation Specification

## Overview
This document outlines the implementation requirements for integrating Uniswap V4 into the BTR contracts system, based on detailed call flow analysis from Tenderly traces.

## Call Flow Analysis Summary

### Complete V4 Deposit Transaction Flow

```
Transaction Entry Point: PositionManager.modifyLiquidities()
├── 1. Permission Management (Permit2 Pattern)
│   ├── permitBatchOwner() - Batch token approvals
│   ├── Signature validation & replay protection
│   ├── Nonce management and expiration checks
│   └── Multi-token permission setup
│
├── 2. PoolManager.unlock() - Central State Management
│   ├── Global reentrancy protection
│   ├── Currency balance tracking initiation
│   ├── unlockCallback() → PositionManager
│   └── State consistency enforcement
│
├── 3. Core Liquidity Operations (within unlock)
│   ├── PoolManager.modifyLiquidity()
│   │   ├── Hook: beforeModifyLiquidity() (conditional)
│   │   ├── Position validation (tick ranges, liquidity)
│   │   ├── Liquidity delta calculations
│   │   ├── Tick crossing logic
│   │   ├── Fee growth updates
│   │   ├── Position state modifications
│   │   └── Hook: afterModifyLiquidity() (conditional)
│   │
│   ├── 4. Currency Settlement Pattern
│   │   ├── Currency debt calculation
│   │   ├── PoolManager.settle() - Pay owed amounts
│   │   ├── PoolManager.take() - Claim excess amounts
│   │   ├── Balance reconciliation
│   │   └── Fee distribution
│   │
│   └── 5. Position NFT Management
│       ├── Position minting (new positions)
│       ├── Position updates (existing positions)
│       ├── Liquidity tracking updates
│       ├── Fee growth checkpoint
│       └── Metadata updates
│
└── 6. Transaction Finalization
    ├── Event emissions (position events, transfers)
    ├── Final state validation
    ├── Gas optimization cleanup
    └── Transaction completion
```

## Key Architectural Differences: V3 vs V4

### V3 Architecture
- **Pool-centric**: Each pool is a separate contract
- **Direct interaction**: Applications interact directly with pool contracts
- **Callback pattern**: Simple mint callbacks for token transfers
- **Position management**: External NFT position manager

### V4 Architecture  
- **Singleton pattern**: Single PoolManager contract manages all pools
- **Unlock pattern**: All operations must go through unlock mechanism
- **Currency abstraction**: Native support for ETH and ERC20 tokens
- **Integrated hooks**: Built-in hook system for custom logic
- **Efficient settlement**: Settle/take pattern for gas optimization

## Implementation Requirements

### 1. Core Adapter Structure

```solidity
contract UniV4Adapter is DEXAdapter {
  // Required V4 contracts
  IUniV4PoolManager public immutable poolManager;
  IUniV4PositionManager public immutable positionManager;
  IUniV4StateView public immutable stateView;
  
  // V4-specific data structures
  struct PoolKey {
    address currency0;
    address currency1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
  }
}
```

### 2. Pool Identification System

**V3 Approach**: Pool address directly used as identifier
```solidity
bytes32 poolId = bytes32(uint256(uint160(poolAddress)));
```

**V4 Approach**: PoolKey hash used as identifier  
```solidity
bytes32 poolId = keccak256(abi.encode(poolKey));
```

### 3. Position Management Changes

#### V3 Position Key
```solidity
bytes32 positionKey = keccak256(abi.encodePacked(owner, lowerTick, upperTick));
```

#### V4 Position Key
```solidity
bytes32 positionKey = keccak256(abi.encodePacked(owner, lowerTick, upperTick, salt));
```

### 4. Liquidity Operations Implementation

#### Mint Pattern (V4)
```solidity
function _mintRange() {
  // 1. Approve tokens to PositionManager
  token0.forceApprove(address(positionManager), amount0);
  token1.forceApprove(address(positionManager), amount1);
  
  // 2. Prepare unlock data
  bytes memory unlockData = abi.encode(poolKey, modifyParams, recipient);
  
  // 3. Execute through unlock pattern
  positionManager.modifyLiquidities(unlockData, deadline);
  
  // 4. Handle callback in unlockCallback()
}
```

#### Burn Pattern (V4)
```solidity
function _burnRange() {
  // 1. Get current position state
  (liquidity, fee0, fee1) = stateView.getPositionInfo(poolId, positionId);
  
  // 2. Prepare burn (negative liquidity delta)
  ModifyLiquidityParams memory params = ModifyLiquidityParams({
    tickLower: range.lowerTick,
    tickUpper: range.upperTick,
    liquidityDelta: -int256(uint256(liquidity)),
    salt: range.positionId
  });
  
  // 3. Execute burn + automatic fee collection
  positionManager.modifyLiquidities(unlockData, deadline);
}
```

### 5. Currency Settlement Implementation

The settle/take pattern is a key V4 innovation for gas efficiency:

```solidity
function unlockCallback(bytes calldata data) external returns (bytes memory) {
  // 1. Decode operation parameters
  (PoolKey memory poolKey, ModifyLiquidityParams memory params, address recipient) = 
    abi.decode(data, (PoolKey, ModifyLiquidityParams, address));
  
  // 2. Execute liquidity modification
  (int256 delta0, int256 delta1) = poolManager.modifyLiquidity(poolKey, params, "");
  
  // 3. Handle currency settlement
  if (delta0 > 0) {
    // We owe the pool currency0
    poolManager.settle(poolKey.currency0);
  } else if (delta0 < 0) {
    // Pool owes us currency0
    poolManager.take(poolKey.currency0, recipient, uint256(-delta0));
  }
  
  if (delta1 > 0) {
    // We owe the pool currency1
    poolManager.settle(poolKey.currency1);
  } else if (delta1 < 0) {
    // Pool owes us currency1
    poolManager.take(poolKey.currency1, recipient, uint256(-delta1));
  }
  
  return abi.encode(delta0, delta1);
}
```

### 6. Required Interface Updates

#### New Interfaces Needed
- `IUniV4PoolManager` - Core singleton pool manager
- `IUniV4PositionManager` - Position NFT management
- `IUniV4StateView` - Read-only state queries
- `IUniV4Router` - Optional routing functionality

#### Interface Methods
```solidity
interface IUniV4PoolManager {
  function unlock(bytes calldata data) external returns (bytes memory);
  function modifyLiquidity(PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData) external returns (int256, int256);
  function settle(address currency) external payable returns (uint256);
  function take(address currency, address to, uint256 amount) external;
}
```

### 7. Gas Optimization Considerations

#### V4 Efficiency Gains
- **Singleton architecture**: Reduces contract deployment costs
- **Settle/take pattern**: Batches currency movements
- **Native ETH support**: Eliminates WETH wrapping costs
- **Hook integration**: Reduces external contract calls

#### Implementation Optimizations
- Batch multiple operations in single unlock call
- Use currency abstraction for ETH positions
- Leverage hook system for custom logic
- Implement efficient position tracking

### 8. Migration Path from V3

#### Data Structure Changes
```solidity
// V3 Range struct
struct V3Range {
  bytes32 poolId;      // Pool contract address
  int24 lowerTick;
  int24 upperTick;
  uint128 liquidity;
}

// V4 Range struct  
struct V4Range {
  bytes32 poolId;      // PoolKey hash
  int24 lowerTick;
  int24 upperTick;
  uint128 liquidity;
  bytes32 salt;        // Additional entropy for position ID
}
```

#### Adapter Interface Compatibility
- Maintain same external interface for BTR system
- Handle V3/V4 differences internally
- Provide migration utilities for existing positions

### 9. Testing Requirements

#### Unit Tests
- PoolKey encoding/decoding
- Position management operations
- Currency settlement logic
- Hook interaction handling

#### Integration Tests
- Full deposit/withdraw cycles
- Multi-position operations
- Gas usage comparisons with V3
- Error handling and edge cases

#### Mainnet Testing
- Small position deployments
- Gas usage analysis
- Hook compatibility testing
- Position migration validation

### 10. Security Considerations

#### V4-Specific Risks
- **Singleton risk**: Single point of failure for all pools
- **Hook vulnerabilities**: Malicious hook contracts
- **Currency confusion**: ETH vs token handling
- **Settlement complexity**: Settle/take logic errors

#### Mitigation Strategies
- Comprehensive input validation
- Hook whitelist management
- Currency type verification
- Settlement amount verification
- Reentrancy protection (already in unlock pattern)

### 11. Deployment Strategy

#### Phase 1: Core Implementation
- [ ] Basic UniV4Adapter contract
- [ ] Pool state reading functions
- [ ] Position query capabilities

#### Phase 2: Liquidity Operations
- [ ] Mint range implementation
- [ ] Burn range implementation
- [ ] Fee collection mechanisms

#### Phase 3: Rollout
- [ ] Gas optimization
- [ ] Comprehensive testing

#### Phase 4: Advanced Features
- [ ] Hook integration support

## Conclusion

This implementation specification provides a comprehensive roadmap for integrating Uniswap V4 into the BTR contracts system. The key architectural changes require careful implementation of the unlock pattern, currency settlement logic, and position management systems while maintaining compatibility with existing BTR interfaces.

The implementation should prioritize security, gas efficiency, and maintainability while leveraging V4's new capabilities for improved user experience. 
