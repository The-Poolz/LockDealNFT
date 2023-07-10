// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFundsManager {
    function handleWithdraw(uint256 poolId, uint256 mainCoinAmount) external;
    function handleRefund(uint256 poolId, uint256 tokenAmount,uint256 mainCoinAmount) external;
}