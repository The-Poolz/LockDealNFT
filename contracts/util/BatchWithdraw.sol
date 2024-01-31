// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILockDealNFT.sol";

contract BatchWithdraw {
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _lockDealNFT) {
        lockDealNFT = _lockDealNFT;
    }

    function batchWithdraw(uint256[] memory tokenIds) external {
        bool isApproved = lockDealNFT.isApprovedForAll(msg.sender, address(this));
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 poolId = tokenIds[i];
            require(lockDealNFT.ownerOf(poolId) == msg.sender, "BatchWithdraw: not owner");
            require(isApproved ||
             lockDealNFT.getApproved(poolId) == address(this), "BatchWithdraw: not approved");
            lockDealNFT.safeTransferFrom(msg.sender, address(lockDealNFT) , poolId); // transfer to lockDealNFT = withdraw
        }
    }
}