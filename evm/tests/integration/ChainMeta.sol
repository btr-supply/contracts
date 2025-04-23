// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 * @title Chain Metadata Library (Test) - Provides chain-specific constants for tests
 * @copyright 2025
 * @notice Defines constants like block numbers or RPC URLs for specific chains used in integration tests
 * @dev Helper library for fork testing setup
 * @author BTR Team
 */

abstract contract EthereumChainMeta {}

abstract contract BNBChainMeta {
    string internal constant RPC_URL = "https://bsc-dataseed.binance.org";
    address internal constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant UNIV3_USDT_USDC_POOL = 0x7bc382DDC5928b0A3511bab35cFEcc11d0e3436d;
    address internal constant THENAV3_USDT_USDC_POOL = 0x5ef7a550c0D814E4DAd63d5976090b22d8728743;
    address internal constant CAKEV3_USDT_USDC_POOL = 0x22536030b9Ae783c6fD5Ec2E9e7b2c827f59C5AD;
    address internal constant UNIV3_FACTORY = 0x7bc382DDC5928b0A3511bab35cFEcc11d0e3436d;
    address internal constant CAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
}

abstract contract PolygonChainMeta {
    // Polygon constants
    string internal constant RPC_URL = "https://polygon-rpc.com";
    address internal constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address internal constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    // ...
}

abstract contract ArbitrumChainMeta {
    // Arbitrum constants
    string internal constant RPC_URL = "https://arb1.arbitrum.io/rpc";
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // ...
}

abstract contract AvalancheChainMeta {}

abstract contract BaseChainMeta {}

abstract contract OptimismChainMeta {}

abstract contract SonicChainMeta {}
