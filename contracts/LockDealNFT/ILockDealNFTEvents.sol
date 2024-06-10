// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IProvider.sol";

/// @title ILockDealNFTEvents interface
/// @notice Contains all events emitted by the LockDealNFT
interface ILockDealNFTEvents {
    event ContractApproved(address indexed contractAddress, bool status);
    event BaseURIChanged(string oldBaseURI, string newBaseURI);
    event TokenWithdrawn(uint256 poolId, address indexed owner, uint256 withdrawnAmount, uint256 leftAmount);
    event PoolSplit(
        uint256 poolId,
        address indexed owner,
        uint256 newPoolId,
        address indexed newOwner,
        uint256 splitLeftAmount,
        uint256 newSplitLeftAmount
    );
}
