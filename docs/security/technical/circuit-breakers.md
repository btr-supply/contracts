# BTR Protocol Circuit Breakers & Emergency Response Mechanisms

This document provides a comprehensive overview of all emergency controls and circuit breakers available in the BTR protocol, including their authorization requirements, implementation details, and operational procedures.

## 1. Protocol-Level Emergency Controls

### 1.1 Global Protocol Pause
**Function**: `pause()` / `unpause()` (ManagementFacet)
**Authorization**: `onlyManager` or `onlyAdmin`
**Scope**: Entire protocol

```solidity
// ManagementFacet.sol
function pause() external onlyManager {
  uint32(0).pause();  // Pauses vault ID 0 (protocol-wide)
}

function unpause() external onlyManager {
  uint32(0).unpause();
}
```

**Effect**: 
- Immediately blocks all user-facing operations across the entire protocol
- Stops deposits, withdrawals, mints, burns, and transfers
- Prevents new vault operations and rebalancing
- Keeps admin functions accessible for emergency response
- Uses vault ID 0 as a special identifier for protocol-wide state

**Use Cases**:
- Critical vulnerability discovered
- Oracle manipulation detected
- Systemic risk to protocol funds
- Emergency maintenance requirements

---

## 2. Vault-Level Emergency Controls

### 2.1 Individual Vault Pause
**Function**: `pauseAlmVault()` / `unpauseAlmVault()` (ALMProtectedFacet)
**Authorization**: `onlyManager` or `onlyAdmin`
**Scope**: Single vault operations

```solidity
// ALMProtectedFacet.sol
function pauseAlmVault(uint32 _vid) external onlyManager {
  _vid.pause();
}

function unpauseAlmVault(uint32 _vid) external onlyManager {
  _vid.unpause();
}
```

**Effect**:
- Suspends all operations for the specified vault
- Blocks deposits, withdrawals, mints, burns for that vault
- Prevents rebalancing operations on the vault
- Other vaults remain operational
- Keeper operations still possible for emergency liquidation

**Use Cases**:
- Vault-specific issues (oracle problems, adapter failures)
- Suspicious activity in individual vaults
- Gradual protocol wind-down
- Testing emergency procedures

### 2.2 Vault Mint Restriction
**Function**: `restrictMint()` (ALMProtectedFacet)
**Authorization**: `onlyManager`
**Scope**: New share issuance for specific vault

```solidity
// ALMProtectedFacet.sol
function restrictMint(uint32 _vid, bool _restricted) external onlyManager {
  _vid.restrictMint(_restricted);
}

// Implementation in LibALMProtected.sol
function restrictMint(ALMVault storage _vault, bool _restricted) internal {
  _vault.mintRestricted = _restricted;
  emit Events.MintRestricted(_vault.id, msg.sender);
}
```

**Effect**:
- When enabled, only whitelisted addresses can mint new shares
- Existing shares remain transferable and redeemable
- Allows controlled entry during recovery periods
- Can be used to prevent dilution during emergencies

**Authorization Check**:
```solidity
// LibAccessControl.sol
function checkAlmMinterUnrestricted(uint32 _vid, address _account) internal view {
  if (!isAlmMinterUnrestricted(_vid, _account)) revert Errors.Unauthorized(ErrorType.ADDRESS);
}

function isAlmMinterUnrestricted(uint32 _vid, address _account) internal view returns (bool) {
  return _vid.vault().mintRestricted ? isWhitelisted(_account) : !isBlacklisted(_account);
}
```

---

## 3. Access Control Circuit Breakers

### 3.1 Revoke All Managers
**Function**: `revokeAllManagers()` (AccessControlFacet)
**Authorization**: Only admin of `MANAGER_ROLE`
**Scope**: All manager permissions

```solidity
// AccessControlFacet.sol
function revokeAllManagers() external {
  AC.revokeAllManagers(S.acc());
}

// LibAccessControl.sol
function revokeAllManagers(AccessControl storage _ac) internal {
  revokeAll(_ac, MANAGER_ROLE);
}
```

**Effect**:
- Immediately removes manager privileges from all accounts
- Preserves role admin to maintain recovery capability
- Prevents further manager operations until roles are re-granted
- Admin can still grant new manager roles

**Use Cases**:
- Manager account compromise
- Suspicious manager activity
- Coordinated attack on protocol management
- Emergency isolation of management functions

### 3.2 Revoke All Keepers
**Function**: `revokeAllKeepers()` (AccessControlFacet)
**Authorization**: Only admin of `KEEPER_ROLE`
**Scope**: All keeper permissions

```solidity
// AccessControlFacet.sol
function revokeAllKeepers() external {
  AC.revokeAllKeepers(S.acc());
}

// LibAccessControl.sol
function revokeAllKeepers(AccessControl storage _ac) internal {
  revokeAll(_ac, KEEPER_ROLE);
}
```

**Effect**:
- Stops all automated rebalancing operations
- Prevents keeper-initiated range management
- Blocks regular maintenance operations
- Emergency liquidation still possible via manager/admin

**Use Cases**:
- Keeper bot compromise
- Malicious rebalancing activity
- Oracle manipulation via keeper operations
- Emergency halt of automated functions

### 3.3 General Role Revocation
**Function**: `revokeAll()` (AccessControlFacet)
**Authorization**: Role admin
**Scope**: All members of specified role

```solidity
// AccessControlFacet.sol
function revokeAll(bytes32 _role) external {
  AC.revokeAll(S.acc(), _role);
}
```

**Effect**: Removes all members from the specified role while preserving role admin capabilities.

---

## 4. Liquidity Management Circuit Breakers

### 4.1 Emergency Liquidation
**Functions**: `zeroOutWeights()` + `rebalance()` (ALMProtectedFacet)
**Authorization**: `onlyManager` + `onlyKeeper` (coordinated action)
**Scope**: Complete vault liquidation

```solidity
// ALMProtectedFacet.sol
function zeroOutWeights(uint32 _vid) external onlyManager {
  _vid.vault().zeroOutWeights();
}

// LibALMProtected.sol
function zeroOutWeights(ALMVault storage _vault) internal {
  uint16[] memory weightsBp = new uint16[](_vault.ranges.length);
  setWeights(_vault, weightsBp);  // Sets all weights to 0
}
```

**Procedure**:
1. **Manager** calls `zeroOutWeights(_vid)` to set all range weights to zero
2. **Keeper** calls `rebalance(_vid, params)` to execute liquidation
3. All liquidity positions are closed and converted to cash
4. Vault becomes fully liquid for user withdrawals

**Effect**:
- Closes all active liquidity positions
- Converts all assets to base tokens (cash)
- Minimizes exposure to DEX/pool risks
- Enables orderly shutdown or migration
- **Works even when vault is paused** - critical for emergency response

**Use Cases**:
- DEX exploit requiring immediate position closure
- Oracle failure affecting position safety
- Preparing for vault migration
- Market volatility requiring risk reduction

### 4.2 Range Weight Management
**Function**: `setWeights()` (ALMProtectedFacet)
**Authorization**: `onlyManager`
**Scope**: Liquidity distribution adjustment

```solidity
// ALMProtectedFacet.sol
function setWeights(uint32 _vid, uint16[] calldata _weights) external onlyManager {
  _vid.vault().setWeights(_weights);
}
```

**Effect**: Allows granular control over liquidity distribution across ranges during emergencies.

---

## 5. Asset Recovery Systems

### 5.1 Comprehensive Asset Rescue
**Functions**: `requestRescue*()` + `rescue()` (RescueFacet)
**Authorization**: `onlyAdmin` (request) + `onlyManager` (execute)
**Scope**: Stuck or lost assets

**Request Functions** (Admin-only):
```solidity
// RescueFacet.sol
function requestRescueNative() external onlyAdmin;
function requestRescueERC20(address[] calldata _tokens) external onlyAdmin;
function requestRescueERC721(address _tokenAddress, uint256 _tokenId) external onlyAdmin;
function requestRescueERC1155(address _tokenAddress, uint256 _tokenId) external onlyAdmin;
```

**Execute Functions** (Manager-only):
```solidity
function rescue(address _receiver, TokenType _tokenType) external onlyManager;
function rescueAll(address _receiver) external onlyManager;
```

**Timelock Protection**:
```solidity
// LibRescue.sol
uint64 public constant DEFAULT_RESCUE_TIMELOCK = 2 days;
uint64 public constant DEFAULT_RESCUE_VALIDITY = 7 days;
```

**Process**:
1. **Admin** requests rescue with `requestRescue*()`
2. **2-day timelock** begins (configurable 1-7 days)
3. **Manager** can execute rescue after timelock expires
4. **7-day validity window** for execution (configurable 1-30 days)
5. Automatic expiry if not executed within validity period

**Safety Features**:
- **Dual authorization**: Admin request + Manager execution
- **Time delay**: Prevents immediate asset extraction
- **Limited validity**: Reduces window for abuse
- **Event logging**: Full audit trail
- **Cancellation**: Admin or requester can cancel

### 5.2 Rescue Request Management
**Functions**: `cancelRescue*()` / `setRescueConfig()` (RescueFacet)

```solidity
// Cancel rescue requests
function cancelRescue(address _receiver, TokenType _tokenType) external;
function cancelRescueAll(address _receiver) external;

// Configure timelock and validity periods
function setRescueConfig(uint64 _timelock, uint64 _validity) external onlyAdmin;
```

**Authorization for Cancellation**:
- Original requester can cancel their own requests
- Admin can cancel any rescue request
- Manager cannot cancel (separation of duties)

---

## 6. Oracle & Price Protection

### 6.1 Stale Price Circuit Breaker
**Function**: `_checkStalePrice()` (internal to DEX adapters)
**Authorization**: Automatic (internal guard)
**Scope**: All range minting/burning operations

```solidity
// ChainlinkProvider.sol example
function _toUsdBp(address _asset, bool _invert) internal view returns (uint256) {
  IChainlinkAggregatorV3 aggregator = aggByAsset[_asset];
  (, int256 answer, , uint256 updatedAt,) = aggregator.latestRoundData();
  
  if (block.timestamp - updatedAt > ttlByFeed[_asset]) {
    revert Errors.StalePrice();
  }
  // ... price calculation
}
```

**Effect**:
- Automatically reverts operations when price data is stale
- Prevents execution with outdated oracle information
- Protects against price manipulation during oracle downtime
- Configurable staleness threshold per feed

### 6.2 TWAP Deviation Protection
**Function**: Vault-level price protection (ManagementFacet)
**Authorization**: `onlyManager`
**Scope**: Individual vault operations

```solidity
// LibManagement.sol
function setVaultPriceProtection(
  ALMVault storage _vault, 
  uint32 _lookback, 
  uint256 _maxDeviation
) internal {
  validatePriceProtection(_lookback, _maxDeviation);
  _vault.lookback = _lookback;
  _vault.maxDeviation = _maxDeviation;
}
```

**Effect**: Protects against operations during excessive price volatility or manipulation.

---

## 7. Account Status Circuit Breakers

### 7.1 Account Blacklisting
**Function**: `setAccountStatus()` / `setAccountStatusBatch()` (ManagementFacet)
**Authorization**: `onlyManager`
**Scope**: Individual or batch account restrictions

```solidity
// ManagementFacet.sol
function setAccountStatus(address _account, AccountStatus _status) external onlyManager;
function setAccountStatusBatch(address[] calldata _accounts, AccountStatus _status) external onlyManager;
```

**Account Status Types**:
- `NONE` - No restrictions
- `WHITELISTED` - Special privileges (can mint when restricted)
- `BLACKLISTED` - Blocked from all operations

**Effect**:
- Immediately restricts access for compromised or malicious accounts
- Can be applied in batches for coordinated response
- Prevents transfers, mints, and burns from blacklisted accounts

---

## 8. Diamond Upgrade Controls

### 8.1 Diamond Cut Capability
**Function**: `diamondCut()` (DiamondCutFacet)
**Authorization**: `onlyAdmin`
**Scope**: Core protocol logic

```solidity
// DiamondCutFacet.sol
function diamondCut(
  FacetCut[] calldata _diamondCut,
  address _init,
  bytes calldata _calldata
) external override onlyAdmin nonReentrant {
  D.diamondCut(S.diam(), _diamondCut, _init, _calldata);
}
```

**Emergency Capabilities**:
- **Immediate upgrades** (no timelock) for critical security fixes
- **Facet replacement** to fix vulnerabilities
- **Function addition/removal** for emergency controls
- **Storage initialization** for emergency state changes

**Risk Mitigation**:
- Admin multisig requirement
- Reentrancy protection
- Event logging for transparency
- Diamond standard compliance

---

## 9. Emergency Response Procedures

### 9.1 Severity-Based Response Matrix

**CRITICAL (Protocol-threatening)**:
1. `pause()` - Immediate protocol shutdown
2. `revokeAllManagers()` / `revokeAllKeepers()` - Isolate compromised roles
3. `diamondCut()` - Deploy emergency fixes
4. Asset rescue preparation

**HIGH (Vault-specific)**:
1. `pauseAlmVault(_vid)` - Isolate affected vault
2. `zeroOutWeights(_vid)` + `rebalance()` - Emergency liquidation
3. `restrictMint(_vid, true)` - Prevent new deposits
4. `setAccountStatus()` - Block malicious accounts

**MEDIUM (Operational)**:
1. `setVaultPriceProtection()` - Adjust risk parameters
2. Oracle feed updates
3. Adapter replacements
4. Fee adjustments

### 9.2 Multi-Step Emergency Liquidation

**Full Protocol Shutdown**:
```solidity
// Step 1: Immediate halt
pause();

// Step 2: Revoke compromised roles
revokeAllManagers();
revokeAllKeepers();

// Step 3: Per-vault liquidation (requires re-granting keeper role)
for each vault:
  zeroOutWeights(vid);
  rebalance(vid, liquidationParams);

// Step 4: Asset recovery if needed
requestRescueERC20([token0, token1]);
// Wait 2 days...
rescue(treasury, TokenType.ERC20);
```

**Gradual Wind-Down**:
```solidity
// Step 1: Prevent new deposits
for each vault:
  restrictMint(vid, true);

// Step 2: Liquidate by priority
for each vault (highest risk first):
  zeroOutWeights(vid);
  rebalance(vid, liquidationParams);

// Step 3: Final shutdown
pause();
```

### 9.3 Authorization Requirements Summary

| Function | Admin | Manager | Keeper | Timelock |
|----------|-------|---------|--------|----------|
| `pause()` / `unpause()` | ✓ | ✓ | ✗ | ✗ |
| `pauseAlmVault()` / `unpauseAlmVault()` | ✓ | ✓ | ✗ | ✗ |
| `restrictMint()` | ✓ | ✓ | ✗ | ✗ |
| `revokeAllManagers()` | ✓* | ✗ | ✗ | ✗ |
| `revokeAllKeepers()` | ✓* | ✗ | ✗ | ✗ |
| `zeroOutWeights()` | ✓ | ✓ | ✗ | ✗ |
| `rebalance()` | ✓ | ✓ | ✓ | ✗ |
| `requestRescue*()` | ✓ | ✗ | ✗ | ✗ |
| `rescue()` | ✗ | ✓ | ✗ | 2 days |
| `diamondCut()` | ✓ | ✗ | ✗ | ✗ |
| `setAccountStatus()` | ✓ | ✓ | ✗ | ✗ |

*Only admin of the specific role

---

## 10. Monitoring & Alerting

### 10.1 Critical Events to Monitor

**Emergency Activations**:
- `Events.Paused()` - Protocol or vault paused
- `Events.MintRestricted()` - Vault mint restrictions enabled
- `Events.RoleRevoked()` - Role revocations (especially mass revocations)

**Asset Movements**:
- `Events.RescueRequested()` - Asset rescue initiated
- `Events.RescueExecuted()` - Assets rescued
- Large withdrawals during emergencies

**Security Events**:
- Failed authorization attempts
- Unusual rebalancing patterns
- Oracle staleness events
- Account status changes

### 10.2 Emergency Response Contacts

**Immediate Response Team**:
- Protocol admins (multisig signers)
- Technical team leads
- Security auditors
- Community moderators

**Communication Channels**:
- Discord emergency channel
- Twitter announcements
- Documentation updates
- Post-incident reports

---

## 11. Testing & Validation

### 11.1 Emergency Drill Procedures

**Monthly Drills**:
- Test pause/unpause functionality
- Verify role revocation mechanisms
- Practice emergency liquidation procedures
- Validate rescue request flows

**Quarterly Reviews**:
- Update emergency response procedures
- Review authorization matrices
- Test communication channels
- Analyze incident response times

### 11.2 Fail-Safe Validation

**Pre-deployment Checks**:
- All circuit breakers functional
- Authorization requirements correct
- Timelock configurations appropriate
- Event emissions working

**Ongoing Monitoring**:
- Circuit breaker effectiveness
- Response time metrics
- Authorization compliance
- Community feedback

---

This comprehensive circuit breaker system provides multiple layers of protection for the BTR protocol, enabling rapid response to various emergency scenarios while maintaining appropriate checks and balances to prevent abuse of emergency powers.
