// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";

/// @title Base LockDeal Events interface
/// @notice Contains all events emitted by the Base Provider
interface IBaseLockDealEvents {
    event TokenWithdrawn(
        DealProvider.BasePoolInfo PoolInfo,
        uint256 Amount,
        uint256 LeftAmount
    );

    event NewPoolCreated(
        DealProvider.BasePoolInfo poolInfo,
        DealProvider.Deal dealInfo,
        uint256 startTime
    );

    event PoolSplit(
        DealProvider.BasePoolInfo OldPool,
        DealProvider.BasePoolInfo NewPool,
        uint256 SplitAmount
    );
}
