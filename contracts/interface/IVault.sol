// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function deposit(address from, uint _amount) external;

    function withdraw(address to, uint _amount) external;
}
