// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";

/// @title ILockDealNFTEvents interface
/// @notice Contains all events emitted by the LockDealNFT
interface ILockDealNFTEvents {
    event ProviderApproved(IProvider indexed provider, bool status);
    event MintInitiated(IProvider indexed provider);
    event BaseURIChanged(string oldBaseURI, string newBaseURI);

    struct BasePoolInfo {
        uint256 poolId;
        address owner;
        address token;
    }
}
