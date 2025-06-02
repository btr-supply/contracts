// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@interfaces/ercs/IERC7802.sol";
import "@interfaces/ercs/IXERC20.sol";

/*
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
 * @@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
 * @@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
 * @@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
 * @@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Mock Bridge - Mock implementation of a cross-chain bridge
 * @copyright 2025
 * @notice Test utility contract simulating bridge behavior for testing
 * @dev Used for testing bridge adapter facets
 * @author BTR Team
 */

contract MockBridge {
    // Token interface
    IERC7802 public token;
    IXERC20 public ixerc20Token;
    // Events

    event BridgeInitialized(address indexed token);
    event BridgeCrosschainMint(address indexed to, uint256 amount);
    event BridgeCrosschainBurn(address indexed from, uint256 amount);
    event BridgeMint(address indexed to, uint256 amount);
    event BridgeBurn(address indexed from, uint256 amount);

    constructor() {}

    // Initialize with token address
    function initialize(address _token) external {
        token = IERC7802(_token);
        ixerc20Token = IXERC20(_token);
        emit BridgeInitialized(_token);
    }

    // Mint tokens to recipient (IERC7802)
    function bridgeMint(address _to, uint256 _amount) external {
        token.crosschainMint(_to, _amount);
        emit BridgeCrosschainMint(_to, _amount);
    }

    // Burn tokens from sender (IERC7802)
    function bridgeBurn(address _from, uint256 _amount) external {
        token.crosschainBurn(_from, _amount);
        emit BridgeCrosschainBurn(_from, _amount);
    }

    // Mint tokens to recipient (IXERC20)
    function bridgeMintIXERC20(address _to, uint256 _amount) external {
        ixerc20Token.mint(_to, _amount);
        emit BridgeMint(_to, _amount);
    }

    // Burn tokens from sender (IXERC20)
    function bridgeBurnIXERC20(address _from, uint256 _amount) external {
        ixerc20Token.burn(_from, _amount);
        emit BridgeBurn(_from, _amount);
    }
}
