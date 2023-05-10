// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";

/// @title Base Locked Deal State contract
/// @notice Contains storage variables, structures
contract BaseLockDealState {
    LockDealNFT public nftContract;
    mapping(uint256 => Deal) public itemIdToDeal;

    struct Deal {
        address tokenAddress;
        uint256 amount;
        uint256 startTime;
    }
}
