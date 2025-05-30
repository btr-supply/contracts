// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@interfaces/ercs/IERC7802.sol";
import "@interfaces/ercs/IXERC20.sol";
import "@abstract/Permissioned.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Bridgeable Base - Abstract contract for generic bridging
 * @copyright 2025
 * @notice Provides base functionality for cross-chain interactions
 * @dev Can be inherited by facets handling specific bridge protocols
 * @author BTR Team
 */

abstract contract ERC20Bridgeable is ERC20, ERC20Permit, ERC165, ReentrancyGuard, IERC7802, IXERC20, Permissioned {
    // Custom Errors
    error ZeroAddress();
    error InvalidRateLimitPeriod();
    error MaxSupplyExceeded();
    error InsufficientAllowance();
    error TransferRestricted();

    // Bridge configuration
    struct Bridge {
        // Mint limits
        uint256 mintingLimit;
        uint256 mintedInPeriod;
        uint256 lastMintResetTime;
        // Burn limits
        uint256 burningLimit;
        uint256 burnedInPeriod;
        uint256 lastBurnResetTime;
    }

    // Custom Events
    event RateLimitPeriodUpdated(uint256 newPeriod);

    // Period for rate limiting
    uint256 public constant MIN_RATE_LIMIT_PERIOD = 1 days;
    uint256 public constant MAX_RATE_LIMIT_PERIOD = 365 days;
    uint256 public rateLimitPeriod = 1 days;

    // Mapping to track approved bridges
    mapping(address => Bridge) public bridges;

    constructor(string memory _name, string memory _symbol, address _diamond)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        Permissioned(_diamond)
    {
        if (_diamond == address(0)) revert ZeroAddress();
    }

    modifier onlyApprovedBridge() {
        if (bridges[msg.sender].mintingLimit == 0) revert IXERC20_NotHighEnoughLimits();
        _;
    }

    modifier transferAllowed(address _from, address _to) {
        if (!canTransfer(_from, _to)) revert TransferRestricted();
        _;
    }

    function setRateLimitPeriod(uint256 _newPeriod) external onlyAdmin {
        if (_newPeriod < MIN_RATE_LIMIT_PERIOD || _newPeriod > MAX_RATE_LIMIT_PERIOD) {
            revert InvalidRateLimitPeriod();
        }
        rateLimitPeriod = _newPeriod;
        emit RateLimitPeriodUpdated(_newPeriod);
    }

    function removeBridge(address _bridge) external onlyAdmin {
        bridges[_bridge].mintingLimit = 0;
        bridges[_bridge].burningLimit = 0;
        emit BridgeLimitsSet(0, 0, _bridge);
    }

    function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external onlyAdmin {
        // Ensure bridge exists
        if (_bridge == address(0)) revert ZeroAddress();

        // Set the limits
        bridges[_bridge].mintingLimit = _mintingLimit;
        bridges[_bridge].burningLimit = _burningLimit;

        // Emit the standard IXERC20 event
        emit BridgeLimitsSet(_mintingLimit, _burningLimit, _bridge);
    }

    function updateMintLimit(address _bridge, uint256 _newLimit, bool _resetCounter) external onlyAdmin {
        if (_bridge == address(0)) revert ZeroAddress();

        bridges[_bridge].mintingLimit = _newLimit;

        if (_resetCounter) {
            bridges[_bridge].mintedInPeriod = 0;
            bridges[_bridge].lastMintResetTime = block.timestamp;
        }

        emit BridgeLimitsSet(_newLimit, bridges[_bridge].burningLimit, _bridge);
    }

    function updateBurnLimit(address _bridge, uint256 _newLimit, bool _resetCounter) external onlyAdmin {
        if (_bridge == address(0)) revert ZeroAddress();

        bridges[_bridge].burningLimit = _newLimit;

        if (_resetCounter) {
            bridges[_bridge].burnedInPeriod = 0;
            bridges[_bridge].lastBurnResetTime = block.timestamp;
        }

        emit BridgeLimitsSet(bridges[_bridge].mintingLimit, _newLimit, _bridge);
    }

    function mintingMaxLimitOf(address _bridge) external view override returns (uint256 limit) {
        return bridges[_bridge].mintingLimit;
    }

    function mintingCurrentLimitOf(address _bridge) external view override returns (uint256 limit) {
        Bridge storage bridgeConfig = bridges[_bridge];

        // Reset period if needed
        if (block.timestamp >= bridgeConfig.lastMintResetTime + rateLimitPeriod) {
            return bridgeConfig.mintingLimit; // Full limit available after reset
        }

        return bridgeConfig.mintingLimit - bridgeConfig.mintedInPeriod;
    }

    function burningMaxLimitOf(address _bridge) external view override returns (uint256 limit) {
        return bridges[_bridge].burningLimit;
    }

    function burningCurrentLimitOf(address _bridge) external view override returns (uint256 limit) {
        Bridge storage bridgeConfig = bridges[_bridge];

        // Reset period if needed
        if (block.timestamp >= bridgeConfig.lastBurnResetTime + rateLimitPeriod) {
            return bridgeConfig.burningLimit; // Full limit available after reset
        }

        return bridgeConfig.burningLimit - bridgeConfig.burnedInPeriod;
    }

    function _supplyFits(uint256 _amount) internal view virtual returns (bool);

    function canTransfer(address _from, address _to) public view virtual returns (bool) {
        return !(permissioned().isBlacklisted(_from) || permissioned().isBlacklisted(_to));
    }

    function _updateMintLimit(address _bridge, uint256 _amount) internal {
        Bridge storage bridgeConfig = bridges[_bridge];

        // Reset period if needed
        if (block.timestamp >= bridgeConfig.lastMintResetTime + rateLimitPeriod) {
            bridgeConfig.mintedInPeriod = 0;
            bridgeConfig.lastMintResetTime = block.timestamp;
        }

        // Check if transfer would exceed limit
        if (bridgeConfig.mintingLimit == 0 || bridgeConfig.mintedInPeriod + _amount > bridgeConfig.mintingLimit) {
            revert IXERC20_NotHighEnoughLimits();
        }

        // Update amount minted in this period
        bridgeConfig.mintedInPeriod += _amount;
    }

    function _updateBurnLimit(address _bridge, uint256 _amount) internal {
        Bridge storage bridgeConfig = bridges[_bridge];

        // Reset period if needed
        if (block.timestamp >= bridgeConfig.lastBurnResetTime + rateLimitPeriod) {
            bridgeConfig.burnedInPeriod = 0;
            bridgeConfig.lastBurnResetTime = block.timestamp;
        }

        // Check if transfer would exceed limit
        if (bridgeConfig.burningLimit == 0 || bridgeConfig.burnedInPeriod + _amount > bridgeConfig.burningLimit) {
            revert IXERC20_NotHighEnoughLimits();
        }

        // Update amount burned in this period
        bridgeConfig.burnedInPeriod += _amount;
    }

    function mint(address _user, uint256 _amount)
        external
        virtual
        override
        onlyApprovedBridge
        transferAllowed(address(0), _user)
    {
        _updateMintLimit(msg.sender, _amount);

        // Check max supply
        if (_supplyFits(_amount)) revert MaxSupplyExceeded();

        _mint(_user, _amount);

        // Emit standard event
        emit CrosschainMint(_user, _amount, msg.sender);
    }

    function burn(address _user, uint256 _amount)
        external
        virtual
        override
        onlyApprovedBridge
        transferAllowed(_user, address(0))
    {
        _updateBurnLimit(msg.sender, _amount);

        // Handle allowance if caller is not the token owner
        if (_user != msg.sender) {
            uint256 currentAllowance = allowance(_user, msg.sender);
            if (currentAllowance < _amount) revert InsufficientAllowance();

            // Decrease the allowance
            _approve(_user, msg.sender, currentAllowance - _amount);
        }

        _burn(_user, _amount);

        emit CrosschainBurn(_user, _amount, msg.sender);
    }

    function crosschainMint(address _to, uint256 _amount)
        external
        virtual
        override
        onlyApprovedBridge
        transferAllowed(address(0), _to)
    {
        _updateMintLimit(msg.sender, _amount);

        // Check max supply
        if (_supplyFits(_amount)) revert MaxSupplyExceeded();

        _mint(_to, _amount);

        emit CrosschainMint(_to, _amount, msg.sender);
    }

    function crosschainBurn(address _from, uint256 _amount)
        external
        virtual
        override
        onlyApprovedBridge
        transferAllowed(_from, address(0))
    {
        _updateBurnLimit(msg.sender, _amount);

        // Handle allowance if caller is not the token owner
        if (_from != msg.sender) {
            uint256 currentAllowance = allowance(_from, msg.sender);
            if (currentAllowance < _amount) revert InsufficientAllowance();

            // Decrease the allowance
            _approve(_from, msg.sender, currentAllowance - _amount);
        }

        _burn(_from, _amount);

        emit CrosschainBurn(_from, _amount, msg.sender);
    }

    // --- ERC20 Overrides ---

    function transfer(address _to, uint256 _amount)
        public
        override(ERC20)
        transferAllowed(msg.sender, _to)
        returns (bool)
    {
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        override(ERC20)
        transferAllowed(_from, _to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _amount);
    }

    // --- ERC165 Implementation ---

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC7802).interfaceId
            || interfaceId == type(IXERC20).interfaceId || interfaceId == type(IERC20).interfaceId
            || interfaceId == type(ERC20Permit).interfaceId || super.supportsInterface(interfaceId);
    }
}
