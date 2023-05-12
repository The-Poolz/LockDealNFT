// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Timed Locked Deal Provider interface
/// @notice Contains all events emitted by the Timed Provider
interface ITimedLockEvents {
    event TokenWithdrawn(
        uint256 PoolId,
        address indexed Recipient,
        uint256 Amount,
        uint256 LeftAmount
    );

    event NewPoolCreated(
        uint256 PoolId,
        address indexed Token,
        uint256 StartTime,
        uint256 FinishTime,
        uint256 StartAmount,
        uint256 DebitedAmount,
        address indexed Owner
    );
}
