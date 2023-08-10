// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBasicWithdraw {
    function withdraw(uint256 poolId) external returns (uint256 withdrawnAmount, bool isFinal);
}