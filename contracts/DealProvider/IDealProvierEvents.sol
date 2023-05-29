// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {
    struct Deal {
        address token; //Part of the Base info
        uint256 leftAmount; //the first param
    }

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
