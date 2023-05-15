// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {

    struct BasePoolInfo{       
        uint256 PoolId;
        address Owner;
        address Token;
    }

    event TokenWithdrawn(
        BasePoolInfo PoolInfo,
        uint256 Amount,
        uint256 LeftAmount
    );

    event NewPoolCreated(
        BasePoolInfo PoolInfo,       
        uint256[] params       
    );

    event PoolSplit(
        BasePoolInfo OldPool,
        BasePoolInfo NewPool,
        uint256 SplitAmount
    );
}
