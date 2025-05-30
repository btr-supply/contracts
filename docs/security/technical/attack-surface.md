# Security Considerations & Attack Surface

This document outlines key areas requiring security scrutiny for the BTR protocol's ALM infrastructure.

## CRITICAL BUGS IDENTIFIED - IMMEDIATE ATTENTION REQUIRED

### 1. Storage Pointer Inconsistency in LibAccessControl.sol
**SEVERITY: CRITICAL**

Multiple functions in `LibAccessControl.sol` inconsistently use storage variables, leading to potential storage corruption:

**Lines with bugs:**
```246:evm/src/libraries/LibAccessControl.sol
RoleData storage roleData = ac.roles[_role];  // Should be _ac.roles[_role]
```

```270-271:evm/src/libraries/LibAccessControl.sol
ac.grantDelay = _grantDelay;        // Should be _ac.grantDelay
ac.acceptanceTtl = _acceptanceTtl;  // Should be _ac.acceptanceTtl
```

```337:evm/src/libraries/LibAccessControl.sol
delete ac.pendingAcceptance[_account];  // Should be _ac.pendingAcceptance[_account]
```

**Impact**: These bugs could cause:
- Undefined behavior when accessing uninitialized storage
- Potential storage corruption 
- Complete failure of access control system
- Possible exploitation to bypass all security restrictions

### 2. Function Name Typos in AccessControlFacet.sol
**SEVERITY: HIGH**

Critical function names have typos that render them unusable:

**Lines with bugs:**
```170:evm/src/facets/AccessControlFacet.sol
function revokeAllManagerst() external {  // Should be revokeAllManagers()
```

```178:evm/src/facets/AccessControlFacet.sol
function revokeAllKeeperst() external {   // Should be revokeAllKeepers()
```

**Impact**: 
- Circuit breaker functions for emergency response are non-functional
- Cannot revoke all managers/keepers in emergency situations
- Reduces emergency response capabilities

### 3. Missing Storage Pointer in LibAccessControl Function Calls
**SEVERITY: MEDIUM**

Several functions in `AccessControlFacet.sol` don't pass storage pointers where required:

**Lines with bugs:**
```48:evm/src/facets/AccessControlFacet.sol
return AC.members(_role);  // Should be AC.members(S.acc(), _role)
```

```54:evm/src/facets/AccessControlFacet.sol  
return AC.timelockConfig();  // Should be AC.timelockConfig(S.acc())
```

```33:evm/src/facets/AccessControlFacet.sol
return AC.admin();  // Should be AC.admin(S.acc())
```

**Impact**: These will likely cause compilation errors or runtime failures.

**IMMEDIATE ACTION REQUIRED**: These bugs must be fixed before any deployment or further testing.

---

## Access Control & Role Management

### Diamond-Based RBAC (`AccessControlFacet`, `PermissionedFacet`, `LibAccessControl`)
**Risk Level: HIGH**

The protocol implements a sophisticated role-based access control system with the following security considerations:

- **Role Hierarchy**: Four primary roles (ADMIN, MANAGER, KEEPER, TREASURY) with proper admin relationships
- **Timelock Protection**: 2-day grant delay with 7-day acceptance window for most role changes
- **Circuit Breakers**: Emergency role revocation capabilities for incident response
- **Multi-signature Integration**: Admin and treasury roles designed for multi-signature wallet control

**Security Features**:
- Timelock mechanism prevents immediate role escalation
- Last admin protection prevents complete lockout
- Role acceptance requirement ensures deliberate transitions
- Keeper role exempted from timelock for operational efficiency

**Attack Vectors**:
- Modifier bypass attempts in facet implementations  
- Race conditions during role acceptance windows
- Social engineering targeting role holders
- Compromised multi-signature wallets

**Mitigation**: Comprehensive role administration testing, proper multi-sig procedures, and monitoring of role state changes.

## Trusted Forwarder Pattern - Diamond to DEX Adapters

### Critical Security Boundary
**Risk Level: CRITICAL**

The protocol uses a **trusted forwarder model** where the Diamond forwards calls to external DEX adapters. This creates a critical security boundary:

```solidity
// Diamond validates permissions, then forwards to adapter
Diamond (validates permissions) → DEX Adapter (trusts diamond)
```

### Diamond Forwarding Vulnerabilities

**1. Permission Validation Bypass**
- **Risk**: Diamond fails to properly validate permissions before forwarding calls
- **Impact**: Unauthorized operations on DEX adapters, fund manipulation
- **Mitigation**: Strict validation in all facet functions before forwarding

**2. Callback Data Injection**
- **Risk**: Malicious callback data passed through diamond to adapters
- **Impact**: Adapter exploitation, unexpected state changes, fund theft
- **Mitigation**: Callback data sanitization and validation

```solidity
// Secure pattern in DEXAdapter
function mintRange(Range calldata _range, bytes calldata _callbackData) 
    external onlyDiamond {
    _validateCallbackData(_callbackData);
    return _mintRange(_range, msg.sender, _callbackData);
}
```

**3. Parameter Tampering**
- **Risk**: Diamond forwards manipulated parameters to adapters
- **Impact**: Incorrect liquidity operations, fee theft, slippage exploitation
- **Mitigation**: Comprehensive parameter validation before forwarding

**4. Cross-Adapter Permission Consistency**
- **Risk**: Different adapters with inconsistent permission models
- **Impact**: Security enforcement gaps across DEX integrations
- **Mitigation**: Standardized adapter interface and consistent permission patterns

### Specific Attack Scenarios

**Scenario 1: Malicious Callback Exploitation**
```solidity
// Potential attack vector
rebalance(vid, maliciousRebalanceParams);
// Diamond forwards to adapter with crafted callback
// Requires: Strict callback validation in diamond
```

**Scenario 2: Parameter Manipulation**
```solidity
// Attack prevention via validation
function forwardToAdapter(Range calldata _range, bytes calldata _data) internal {
    _validateRange(_range);
    _validateCallbackData(_data);
    _validateRecipient(msg.sender);
    adapter.operation(_range, _data);
}
```

**Scenario 3: Permission Escalation Prevention**
```solidity
// Consistent permission model across all adapters
interface IStandardizedAdapter {
    function mintRange(...) external onlyDiamond;
    function collectFees(...) external onlyTreasury; 
    function burnRange(...) external onlyDiamond;
}
```

## Diamond Upgrade Security (`DiamondCutFacet`)
**Risk Level: HIGH**

Diamond upgrades present significant security considerations:

- **Upgrade Authorization**: Only `onlyAdmin` (multi-signature) can perform upgrades
- **Facet Replacement**: New facets could override access control logic
- **Storage Compatibility**: Upgrades must maintain storage layout integrity
- **Immediate Effect**: No timelock on upgrades (operational requirement)

**Security Model**:
- Multi-signature admin control for upgrade authorization
- Comprehensive testing before deployment
- Storage layout verification
- Emergency upgrade capabilities for security patches

**Attack Vectors**:
- Compromised admin multi-signature wallet
- Malicious facet implementation with backdoors
- Storage layout corruption causing state inconsistency
- Function selector collisions between facets

## Reentrancy Protection (`NonReentrantFacet`, `ALMFacet`, `ERC1155VaultsFacet`)
**Risk Level: HIGH**

Cross-contract calls during vault operations create reentrancy risks:

- **External DEX Calls**: During rebalancing operations
- **Token Transfers**: In deposit/withdrawal flows
- **Callback Handling**: DEX adapter callback execution
- **Cross-Facet Calls**: Diamond internal function calls

**Protected Functions**:
- `ALMFacet.deposit/withdraw` - User fund operations
- `ALMProtectedFacet.rebalance` - Keeper rebalancing
- `ERC1155VaultsFacet.mint/burn` - Share token operations
- `AccessControlFacet.acceptRole` - Role state changes

**Mitigation**: `nonReentrant` modifier on all state-changing external functions.

## Fund Handling Security (`ALMFacet`, `LibALM`, `ERC1155VaultsFacet`)
**Risk Level: CRITICAL**

Core vault operations handle user funds with strict security requirements:

- **Accounting Integrity**: Precise share calculations and fee applications
- **Fund Protection**: Prevention of unauthorized withdrawals or transfers
- **Share Token Security**: ERC1155 mint/burn integrity
- **Fee Calculation**: Accurate protocol and performance fee handling

**Critical Components**:
- Deposit/withdrawal mathematics in `LibALM`
- Share calculation precision in `ERC1155VaultsFacet`
- Fee accounting across all vault operations
- Range liquidity calculations and validations

**Security Measures**:
- Comprehensive mathematical validation
- Overflow/underflow protection
- State consistency checks
- Event emission for transparency

## External Call Security (`SwapFacet`, `LibSwap`, DEX Adapters)
**Risk Level: HIGH**

External DEX interactions introduce multiple risk vectors:

- **DEX Contract Trust**: Reliance on potentially unaudited external contracts
- **Return Data Validation**: Proper handling of external call responses
- **Transaction Failure**: Graceful handling of failed external operations
- **MEV Protection**: Mitigation of maximum extractable value attacks

**Security Patterns**:
- Adapter validation before integration
- Return value verification
- Proper error handling and reversion
- Slippage protection mechanisms

## Asset Rescue Security (`RescueFacet`, `LibRescue`)
**Risk Level: MEDIUM**

The asset rescue mechanism provides emergency fund recovery with security controls:

- **Two-Phase Process**: Admin request followed by manager execution
- **Timelock Protection**: Mandatory delay before execution
- **Scope Limitation**: Only rescue accidentally sent tokens
- **Transparency**: Full event emission for audit trails

**Security Model**:
- `onlyAdmin` can request rescue operations
- `onlyManager` can execute after timelock expiry
- Event emission for all rescue activities
- Cancellation mechanism for safety

## Configuration Security (`ManagementFacet`, `ALMProtectedFacet`)
**Risk Level: MEDIUM**

Protocol configuration requires careful parameter management:

- **Access Restrictions**: Proper whitelist/blacklist enforcement
- **Fee Structures**: Secure fee collection and distribution
- **Vault Parameters**: Supply limits and minting restrictions
- **Oracle Settings**: Price deviation and staleness protection

**Critical Parameters**:
- Account status management (whitelists, blacklists)
- Fee collection addresses and percentages
- Vault supply limits and restrictions
- Oracle price deviation thresholds

## Recommendations

### Ongoing Security Priorities

1. **Access Control Monitoring**: Real-time alerts for role changes and timelock activities
2. **Diamond Forwarding Validation**: Comprehensive testing of all adapter interactions
3. **Callback Security Auditing**: Regular review of callback data handling patterns
4. **Parameter Validation Testing**: Automated testing of all forwarding validations
5. **Multi-Signature Procedures**: Secure key management and signing processes

### Security Best Practices

1. **Comprehensive Testing**: Unit tests, integration tests, and invariant testing
2. **Code Reviews**: Multi-party review of all access control changes
3. **Monitoring Systems**: Detection of suspicious activity and role changes
4. **Incident Response**: Documented procedures for security incidents
5. **Regular Audits**: Periodic security audits of new features and changes

### Testing Coverage

- **Access Control Tests**: `AccessControlTest.t.sol`, `ManagementTest.t.sol`
- **Diamond Integration Tests**: Comprehensive adapter interaction testing
- **Reentrancy Protection Tests**: Dedicated attack simulation testing
- **Emergency Response Tests**: Circuit breaker and rescue mechanism validation
- **Economic Security Tests**: Fee calculation and distribution verification

The BTR protocol implements a robust security framework designed for safe multi-chain ALM operations with appropriate safeguards for high-value DeFi infrastructure.
