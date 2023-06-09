// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {
    event NewPoolCreated(uint256 indexed poolId, address indexed owner, address indexed token, uint256[] params);

    event TokenWithdrawn(
        uint256 poolId,
        address indexed owner,
        uint256 withdrawnAmount,
        uint256 leftAmount
    );

    event PoolSplit(
        uint256 poolId,
        address indexed owner,
        uint256 newPoolId,
        address indexed newOwner,
        uint256 splitLeftAmount,
        uint256 newSplitLeftAmount
    );
}
