// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdvancedWithdraw {
    function withdraw(uint256 poolId, address owner) external returns (uint256 withdrawnAmount, bool isFinal);
}