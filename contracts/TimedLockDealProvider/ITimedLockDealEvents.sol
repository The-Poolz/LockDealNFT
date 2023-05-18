// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseProvider/BaseLockDealProvider.sol";

/// @title Base LockDeal Events interface
/// @notice Contains all events emitted by the Base Provider
interface ITimedLockDealEvents {
    struct TimedDeal {
        uint256 finishTime;
        uint256 withdrawnAmount;
    }

    event TokenWithdrawn(
        DealProvider.BasePoolInfo PoolInfo,
        uint256 Amount,
        uint256 LeftAmount
    );

    event NewPoolCreated(
        DealProvider.BasePoolInfo poolInfo,
        DealProvider.Deal dealInfo,
        uint256 startTime,
        uint256 finishTime
    );

    event PoolSplit(
        DealProvider.BasePoolInfo OldPool,
        DealProvider.BasePoolInfo NewPool,
        uint256 SplitAmount,
        address token
    );
}
