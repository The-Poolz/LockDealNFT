// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Provider interface
/// @notice Contains all events emitted by the Provider
interface IProvierEvents {
    struct BasePoolInfo {
        uint256 poolId;
        address owner;
        address token;
    }

    event NewPoolCreated(BasePoolInfo poolInfo, uint256[] params);
}
