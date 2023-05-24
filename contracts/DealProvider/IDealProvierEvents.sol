// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {
    struct BasePoolInfo {
        uint256 poolId;
        address owner;
        address token;
    }

    struct Deal {
        address token; //Part of the Base info
        uint256 leftAmount; //the first param
    }

    event TokenWithdrawn(
        uint256 poolId,
        address indexed owner,
        uint256 amount,
        uint256 leftAmount
    );

    event NewPoolCreated(BasePoolInfo poolInfo, uint256[] params);

    event PoolSplit(
        uint256 poolId,
        address indexed owner,
        uint256 newPoolId,
        address indexed newOwner,
        uint256 splitLeftAmount,
        uint256 newSplitLeftAmount
    );
}
