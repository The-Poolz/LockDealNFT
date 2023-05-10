// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base Locked Deal Provider interface
/// @notice Contains all events emitted by the Base Provider
interface IBaseLockEvents {
    event TokenWithdrawn(
        uint256 poolId,
        address indexed token,
        uint256 amount,
        address indexed owner
    );

    event NewPoolCreated(
        uint256 tokenId,
        address indexed token,
        uint256 startTime,
        uint256 amount,
        address indexed owner
    );
}
