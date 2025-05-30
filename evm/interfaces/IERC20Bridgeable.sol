// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@interfaces/ercs/IERC7802.sol";
import "@interfaces/ercs/IXERC20.sol";

interface IERC20Bridgeable is IERC20, IERC20Permit, IERC165, IERC7802, IXERC20 {
    // Rate limit management
    function setRateLimitPeriod(uint256 _newPeriod) external;
    function removeBridge(address _bridge) external;
    function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external;
    function updateMintLimit(address _bridge, uint256 _newLimit, bool _resetCounter) external;
    function updateBurnLimit(address _bridge, uint256 _newLimit, bool _resetCounter) external;

    // Bridge limit views
    function mintingMaxLimitOf(address _bridge) external view returns (uint256 limit);
    function mintingCurrentLimitOf(address _bridge) external view returns (uint256 limit);
    function burningMaxLimitOf(address _bridge) external view returns (uint256 limit);
    function burningCurrentLimitOf(address _bridge) external view returns (uint256 limit);

    // Transfer restrictions
    function canTransfer(address _from, address _to) external view returns (bool);

    // Constants
    function MIN_RATE_LIMIT_PERIOD() external view returns (uint256);
    function MAX_RATE_LIMIT_PERIOD() external view returns (uint256);
    function rateLimitPeriod() external view returns (uint256);
}
