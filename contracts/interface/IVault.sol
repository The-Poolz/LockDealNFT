// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function deposit(address from, uint amount) external;
    function withdraw(address to, uint amount) external;
}
