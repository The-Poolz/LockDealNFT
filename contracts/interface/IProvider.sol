// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProvider {
    function withdraw(
        uint256 itemId
    ) external returns (uint256 withdrawnAmount, bool isClosed);

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external;
}
