// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {MintProceeds} from "@BTRTypes.sol";

interface IALMUser {
    // Preview functions
    function previewDeposit(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory _res);
    function previewMint(uint32 _vid, uint256 _shares, address _receiver) external returns (MintProceeds memory _res);
    function previewRedeem(uint32 _vid, uint256 _shares, address _receiver)
        external
        returns (BurnProceeds memory _res);
    function previewWithdraw(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (BurnProceeds memory _res);

    // Deposit functions
    function deposit(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory _res);

    function depositExact0(uint32 _vid, uint256 _exactAmount0, address _receiver)
        external
        returns (MintProceeds memory _res);

    function depositExact1(uint32 _vid, uint256 _exactAmount1, address _receiver)
        external
        returns (MintProceeds memory _res);

    function depositSingle0(uint32 _vid, uint256 _amount0, address _receiver)
        external
        returns (MintProceeds memory _res);

    function depositSingle1(uint32 _vid, uint256 _amount1, address _receiver)
        external
        returns (MintProceeds memory _res);

    // Mint function
    function mint(uint32 _vid, uint256 _shares, address _receiver) external returns (MintProceeds memory _res);

    // Withdraw functions
    function withdraw(uint32 _vid, uint256 _amount0, uint256 _amount1, address _receiver)
        external
        returns (BurnProceeds memory _res);

    function withdrawExact0(uint32 _vid, uint256 _exactAmount0, address _receiver)
        external
        returns (BurnProceeds memory _res);

    function withdrawExact1(uint32 _vid, uint256 _exactAmount1, address _receiver)
        external
        returns (BurnProceeds memory _res);

    function withdrawSingle0(uint32 _vid, uint256 _shares, address _receiver)
        external
        returns (BurnProceeds memory _res);

    function withdrawSingle1(uint32 _vid, uint256 _shares, address _receiver)
        external
        returns (BurnProceeds memory _res);

    // Redeem function
    function redeem(uint32 _vid, uint256 _shares, address _receiver) external returns (BurnProceeds memory _res);
}
