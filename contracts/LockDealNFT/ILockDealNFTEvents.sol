// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ILockDealNFTEvents interface
/// @notice Contains all events emitted by the LockDealNFT
interface ILockDealNFTEvents {
    event ProviderApproved(address indexed provider, bool status);
    event MintInitiated(address indexed provider);

    struct BasePoolInfo {
        uint256 poolId;
        address owner;
        address token;
    }
}
