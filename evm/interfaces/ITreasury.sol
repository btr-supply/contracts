// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Fees} from "@/BTRTypes.sol";

interface ITreasuryFacet {
    function initializeTreasury() external;
    function setCollector(address _collector) external;
    function collector() external view returns (address);
    function validateFees(Fees memory fees) external pure;
    function setDefaultFees(Fees memory fees) external;
    function defaultFees() external view returns (Fees memory);
    function setAlmVaultFees(uint32 vid, Fees calldata fees) external;
    function almVaultFees(uint32 vid) external view returns (Fees memory);
    function collectAlmFees(uint32 vid) external;
}
