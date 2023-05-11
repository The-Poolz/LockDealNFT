// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deal Provider interface
/// @notice Contains all events emitted by the Provider
interface IDealProvierEvents {
    event PoolSplit(
        uint256 OldPoolId,
        uint256 NewPoolId,
        uint256 OriginalLeftAmount,
        uint256 NewAmount,
        address indexed OldOwner,
        address indexed NewOwner
    );
}
