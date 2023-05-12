// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {
    event PoolSplit(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 originalLeftAmount,
        uint256 newAmount,
        address indexed oldOwner,
        address indexed newOwner
    );
}
