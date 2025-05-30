# Treasury Protocol Flows

This document outlines the treasury management and fee collection operations within the BTR protocol, focusing on fee configuration, collection mechanisms, and treasury administration performed by admins, managers, and treasury roles.

## Overview

The BTR treasury system manages protocol revenue streams through:

- **Fee Configuration**: Setting default and vault-specific fee structures
- **Fee Collection**: Automated and manual collection of protocol fees
- **Treasury Management**: Collector address configuration and fund distribution
- **Custom Fee Handling**: User-specific fee overrides and validation

## Treasury Architecture

### Core Components

```mermaid
graph TD
    A[TreasuryFacet] --> B[LibTreasury]
    B --> C[Fee Configuration]
    B --> D[Fee Collection]
    B --> E[Treasury Storage]
    
    C --> F[Default Fees]
    C --> G[Vault-Specific Fees]
    C --> H[Custom User Fees]
    
    D --> I[ALM Vault Fees]
    D --> J[Management Fees]
    D --> K[Performance Fees]
```

### Fee Structure

```solidity
struct Fees {
    uint16 entryFeeBp;      // Entry fee in basis points
    uint16 exitFeeBp;       // Exit fee in basis points
    uint16 performanceFeeBp; // Performance fee in basis points
    uint16 managementFeeBp;  // Management fee in basis points
}
```

## Treasury Initialization

### 1. Treasury Setup

```mermaid
graph TD
    A[Deploy Treasury System] --> B[Initialize TreasuryFacet]
    B --> C[Set Treasury Storage]
    C --> D[Configure Default Fees]
    D --> E[Set Collector Address]
    E --> F[Validate Fee Structure]
```

**Function**: `TreasuryFacet.initializeTreasury()`

**Initial Configuration**:
- Initialize treasury storage
- Set default fee structure
- Configure collector address
- Validate fee parameters

## Collector Management

### 1. Collector Configuration

```mermaid
graph TD
    A[Admin calls setCollector] --> B[Validate collector address]
    B --> C[Check admin permissions]
    C --> D[Update collector mapping]
    D --> E[Emit CollectorUpdated event]
```

**Function**: `TreasuryFacet.setCollector()`

**Access Control**: Only admins can set the collector address

**Validation**:
- Non-zero address required
- Admin role verification
- Event emission for transparency

### 2. Collector Query

```mermaid
graph TD
    A[Query collector] --> B[Read treasury storage]
    B --> C[Return collector address]
```

**Function**: `TreasuryFacet.collector()`

**Returns**: Current treasury collector address

## Fee Configuration

### 1. Default Fee Management

```mermaid
graph TD
    A[Admin calls setDefaultFees] --> B[Validate fee structure]
    B --> C[Check fee limits]
    C --> D[Update default fees]
    D --> E[Apply to vault ID 0]
    E --> F[Emit DefaultFeesUpdated event]
```

**Function**: `TreasuryFacet.setDefaultFees()`

**Fee Validation**:
- Entry fee ≤ maximum allowed
- Exit fee ≤ maximum allowed  
- Performance fee ≤ maximum allowed
- Management fee ≤ maximum allowed

### 2. Vault-Specific Fee Configuration

```mermaid
graph TD
    A[Manager calls setAlmVaultFees] --> B[Validate vault ID]
    B --> C[Validate fee structure]
    C --> D[Check manager permissions]
    D --> E[Update vault fees]
    E --> F[Store fee configuration]
    F --> G[Emit VaultFeesUpdated event]
```

**Function**: `TreasuryFacet.setAlmVaultFees()`

**Parameters**:
- `vid`: Vault ID
- `fees`: Fee structure for the vault

**Access Control**: Only managers can set vault-specific fees

### 3. Custom User Fee Configuration

```mermaid
graph TD
    A[Manager calls setCustomFees] --> B[Validate user address]
    B --> C[Validate fee structure]
    C --> D[Check manager permissions]
    D --> E[Update custom fees]
    E --> F[Store user-specific fees]
    F --> G[Emit CustomFeesUpdated event]
```

**Function**: `ManagementFacet.setCustomFees()` (delegated to LibTreasury)

**Parameters**:
- `_user`: User address
- `_fees`: Custom fee structure

**Access Control**: Only managers can set custom fees

## Fee Validation

### 1. Fee Structure Validation

```mermaid
graph TD
    A[Fee Validation Request] --> B[Check entry fee limits]
    B --> C[Check exit fee limits]
    C --> D[Check performance fee limits]
    D --> E[Check management fee limits]
    E --> F{All Valid?}
    F -->|Yes| G[Accept Fee Structure]
    F -->|No| H[Revert with InvalidFees]
```

**Function**: `TreasuryFacet.validateFees()`

**Validation Rules**:
- Entry fee: 0 ≤ fee ≤ MAX_ENTRY_FEE_BP
- Exit fee: 0 ≤ fee ≤ MAX_EXIT_FEE_BP
- Performance fee: 0 ≤ fee ≤ MAX_PERFORMANCE_FEE_BP
- Management fee: 0 ≤ fee ≤ MAX_MANAGEMENT_FEE_BP

### 2. Fee Limit Constants

```solidity
uint256 public constant MAX_ENTRY_FEE_BP = 500;      // 5%
uint256 public constant MAX_EXIT_FEE_BP = 500;       // 5%
uint256 public constant MAX_PERFORMANCE_FEE_BP = 2000; // 20%
uint256 public constant MAX_MANAGEMENT_FEE_BP = 200;   // 2%
```

## Fee Collection Operations

### 1. ALM Vault Fee Collection

```mermaid
graph TD
    A[Treasury calls collectAlmFees] --> B[Validate vault ID]
    B --> C[Check treasury permissions]
    C --> D[Calculate collectable fees]
    D --> E[Transfer fees to collector]
    E --> F[Reset vault fee accounting]
    F --> G[Update collection timestamp]
    G --> H[Emit ALMFeesCollected event]
```

**Function**: `TreasuryFacet.collectAlmFees()`

**Access Control**: Only treasury role can collect fees

**Collection Process**:
1. Validate vault exists and has pending fees
2. Calculate total collectable amount (management + performance)
3. Transfer tokens to treasury collector
4. Reset vault fee accounting
5. Update last collection timestamp

### 2. Fee Calculation Logic

```mermaid
graph TD
    A[Fee Calculation] --> B[Calculate Management Fees]
    B --> C[Calculate Performance Fees]
    C --> D[Sum Total Fees]
    D --> E[Apply Fee Caps]
    E --> F[Return Fee Amounts]
    
    B --> B1[Time-based calculation]
    B --> B2[TVL percentage]
    
    C --> C1[Revenue percentage]
    C --> C2[LP fee share]
```

**Management Fee Calculation**:
```solidity
managementFee = (tvl * managementFeeBp * timePeriod) / (BPS * SECONDS_PER_YEAR)
```

**Performance Fee Calculation**:
```solidity
performanceFee = (lpFeeRevenue * performanceFeeBp) / BPS
```

## Fee Query Operations

### 1. Default Fee Queries

```mermaid
graph TD
    A[Query Default Fees] --> B[Read vault ID 0 fees]
    B --> C[Return fee structure]
```

**Function**: `TreasuryFacet.defaultFees()`

**Returns**: Default fee structure applied to new vaults

### 2. Vault-Specific Fee Queries

```mermaid
graph TD
    A[Query Vault Fees] --> B[Validate vault ID]
    B --> C[Read vault fee configuration]
    C --> D{Custom Fees Set?}
    D -->|Yes| E[Return vault-specific fees]
    D -->|No| F[Return default fees]
```

**Function**: `TreasuryFacet.almVaultFees()`

**Parameters**: `vid` - Vault ID

**Returns**: Fee structure for the specified vault

## Fee Accrual Process

### 1. Management Fee Accrual

```mermaid
graph TD
    A[Time-based Trigger] --> B[Calculate time elapsed]
    B --> C[Get vault TVL]
    C --> D[Apply management fee rate]
    D --> E[Accrue fee amount]
    E --> F[Update last accrual time]
    F --> G[Store pending fees]
```

**Accrual Logic**:
- Triggered during vault operations
- Time-proportional calculation
- Based on vault TVL
- Stored as pending collection

### 2. Performance Fee Accrual

```mermaid
graph TD
    A[LP Fee Collection] --> B[Calculate protocol share]
    B --> C[Apply performance fee rate]
    C --> D[Accrue fee amount]
    D --> E[Store pending fees]
    E --> F[Update fee accounting]
```

**Accrual Logic**:
- Triggered during rebalancing
- Based on LP fee revenue
- Percentage of generated fees
- Immediate accrual to pending

## Treasury Accounting

### 1. Fee Tracking

```mermaid
graph TD
    A[Fee Events] --> B[Management Fee Accrual]
    A --> C[Performance Fee Accrual]
    A --> D[Fee Collection]
    
    B --> E[Update Pending Management]
    C --> F[Update Pending Performance]
    D --> G[Reset Pending Amounts]
    
    E --> H[Treasury Storage]
    F --> H
    G --> H
```

### 2. Collection History

```mermaid
graph TD
    A[Collection Event] --> B[Record Collection Amount]
    B --> C[Update Collection Timestamp]
    C --> D[Emit Collection Event]
    D --> E[Update Treasury Metrics]
```

## Revenue Streams

### 1. Entry/Exit Fees

```mermaid
graph TD
    A[User Operation] --> B{Operation Type}
    B -->|Deposit| C[Apply Entry Fee]
    B -->|Withdrawal| D[Apply Exit Fee]
    C --> E[Transfer Fee to Treasury]
    D --> F[Transfer Fee to Treasury]
    E --> G[Update Fee Accounting]
    F --> G
```

### 2. Management Fees

```mermaid
graph TD
    A[Vault Operation] --> B[Check Time Elapsed]
    B --> C[Calculate Management Fee]
    C --> D[Accrue to Pending]
    D --> E[Update Last Accrual Time]
```

### 3. Performance Fees

```mermaid
graph TD
    A[Rebalance Operation] --> B[Collect LP Fees]
    B --> C[Calculate Performance Share]
    C --> D[Accrue to Pending]
    D --> E[Update Fee Metrics]
```

## Access Control Matrix

| Operation | Admin | Manager | Treasury | Keeper | Public |
|-----------|-------|---------|----------|--------|--------|
| Initialize Treasury | ✓ | ✗ | ✗ | ✗ | ✗ |
| Set Collector | ✓ | ✗ | ✗ | ✗ | ✗ |
| Set Default Fees | ✓ | ✗ | ✗ | ✗ | ✗ |
| Set Vault Fees | ✗ | ✓ | ✗ | ✗ | ✗ |
| Set Custom Fees | ✗ | ✓ | ✗ | ✗ | ✗ |
| Collect ALM Fees | ✗ | ✗ | ✓ | ✗ | ✗ |
| Validate Fees | ✗ | ✗ | ✗ | ✗ | ✓ |
| Query Fees | ✗ | ✗ | ✗ | ✗ | ✓ |
| Query Collector | ✗ | ✗ | ✗ | ✗ | ✓ |

## Integration Examples

### 1. Setting Up Default Fees

```solidity
// Configure default fee structure
Fees memory defaultFees = Fees({
    entryFeeBp: 25,      // 0.25%
    exitFeeBp: 25,       // 0.25%
    performanceFeeBp: 1000, // 10%
    managementFeeBp: 100   // 1%
});

treasuryFacet.setDefaultFees(defaultFees);
```

### 2. Vault-Specific Fee Configuration

```solidity
// Set custom fees for high-performance vault
Fees memory vaultFees = Fees({
    entryFeeBp: 50,       // 0.5%
    exitFeeBp: 50,        // 0.5%
    performanceFeeBp: 1500, // 15%
    managementFeeBp: 150    // 1.5%
});

treasuryFacet.setAlmVaultFees(vaultId, vaultFees);
```

### 3. Fee Collection

```solidity
// Collect all pending fees for a vault
treasuryFacet.collectAlmFees(vaultId);
```

## Error Handling

### Common Error Scenarios

1. **Invalid Fee Structure**: Fees exceed maximum limits
2. **Unauthorized Access**: Non-treasury role attempting collection
3. **Invalid Vault**: Vault doesn't exist or has no fees
4. **Zero Address**: Attempting to set zero collector address

### Recovery Procedures

1. **Fee Limit Exceeded**: Adjust fees within valid ranges
2. **Access Denied**: Verify role assignments
3. **Collection Failed**: Check vault state and pending amounts
4. **Configuration Error**: Reset to default configuration

## Monitoring and Metrics

### 1. Fee Performance Tracking

```mermaid
graph TD
    A[Fee Collection Events] --> B[Aggregate by Time Period]
    B --> C[Calculate Revenue Metrics]
    C --> D[Performance Analysis]
    D --> E[Fee Optimization]
```

### 2. Treasury Health Monitoring

- **Collection Frequency**: How often fees are collected
- **Revenue Growth**: Trend analysis of fee generation
- **Fee Efficiency**: Performance vs. management fee balance
- **Vault Profitability**: Per-vault revenue analysis

This comprehensive treasury protocol flow documentation ensures proper understanding and implementation of all treasury management operations within the BTR protocol.
