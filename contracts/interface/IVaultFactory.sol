// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultFactory{
    function CreateNewVault(address tokenAddress) external returns(address);
}