// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustomItemInterface {
    function mint(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime
    ) external;
    function withdraw(uint256 itemId) external;
    function split(address to, uint256 itemId, uint256 splitAmount) external;
}
