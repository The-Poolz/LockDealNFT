// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDeposit {
    function deposit(uint256 poolId, uint256 amount) external;
}