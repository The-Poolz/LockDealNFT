// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomLockedDeal {
    function withdraw(
        uint256 itemId
    ) external returns (uint256 withdrawnAmount);
    function split(address to, uint256 itemId, uint256 splitAmount) external;
}
