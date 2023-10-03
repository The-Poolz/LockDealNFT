// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayVaultProvider {
    function createNewDelayVault(address owner, uint256[] memory params) external;

    function Token() external view returns (address);

    function getLeftAmount(address owner, uint8 theType) external view returns (uint256);

    function theTypeOfTotalAmount(address user) external view returns (uint8);
}
