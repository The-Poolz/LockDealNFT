// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILockDealNFT.sol";

contract BatchWithdraw {
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _lockDealNFT) {
        lockDealNFT = _lockDealNFT;
    }

    function batchWithdraw(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(lockDealNFT.ownerOf(tokenIds[i]) == msg.sender, "BatchWithdraw: not owner");
            require(lockDealNFT.isApprovedForAll(msg.sender, address(this)) ||
             lockDealNFT.getApproved(tokenIds[i]) == address(this), "BatchWithdraw: not approved");
            lockDealNFT.safeTransferFrom(msg.sender, address(lockDealNFT) , tokenIds[i]);
        }
    }
}
