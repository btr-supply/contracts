# BTR Contracts TODO

## 🧪 Testing & Integration

### DEX Adapter Testing
- [ ] Unit tests for DEX adapter functionality
- [ ] Standalone adapter integration tests
- [ ] Single-sided deposit/withdrawal tests
- [ ] Ratio-based fee adjustment tests

### Core System Testing
- [ ] Comprehensive single-sided operations tests
- [ ] Diamond pattern upgrade tests
- [ ] Oracle price feed integration tests
- [ ] Cross-chain bridging tests

---

## 📝 Documentation & Quality

### Code Standards
- [ ] Ensure all parameters start with "_" across `./evm/src` and `./evm/interfaces`
- [ ] Add concise NatSpec documentation
- [ ] Limit inline comments to complex code only (end of lines)

### Contract Optimization
- [ ] Gas usage optimization review
- [ ] Consistent error handling patterns
- [ ] Standardize event emission
- [ ] Security patterns review

### User Documentation
- [ ] Deployment guides for target networks
- [ ] Adapter configuration documentation

---

## 🚀 Deployment Preparation

### Network Configuration
- [ ] Configure deployment scripts for target networks
- [ ] Set up oracle price feeds per network
- [ ] Configure bridge limits and parameters
- [ ] Prepare multi-sig wallet configurations

### Security & Monitoring
- [ ] Internal security review
- [ ] External audit preparation
- [ ] Emergency pause mechanisms
- [ ] Monitoring and alerting systems

---

## ✅ Recently Completed

### Deployment Architecture Simplification
- ✅ Removed Python generator scripts and templates
- ✅ Created modular deployment architecture with individual deployer contracts
- ✅ Each facet has its own self-destructing deployer (e.g., `AccessControlFacetDeployer.sol`)
- ✅ Deployers extract bytecode using `type(Contract).creationCode` in constructor
- ✅ Deployers call CreateX with bytecode + salt, then self-destruct
- ✅ Script calls all deployer constructors sequentially
- ✅ Same logic works in tests and production deployments
- ✅ No contract size limits - each deployer is minimal and focused

### ALM Test Architecture
- ✅ Implemented `DM.priceX96RangeToTicks()` with inversion parameter
- ✅ Organized test flows and comprehensive operations
- ✅ Fixed console.log and validation issues
- ✅ All diamond and facet contracts compile successfully

---

## 🔮 Future Enhancements

### Multi-Chain Support
- [ ] Automatic chain detection in scripts
- [ ] Chain-specific deployment configurations
- [ ] Unified deployment status tracking

### Developer Experience
- [ ] Deployment preview functionality
- [ ] Deployment rollback mechanisms
- [ ] Gas usage benchmarking
- [ ] Deployment status dashboard
