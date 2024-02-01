// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INFTView.sol";

contract BatchWithdraw {
    ILockDealNFTViews public lockDealNFT;

    constructor(ILockDealNFTViews _lockDealNFT) {
        lockDealNFT = _lockDealNFT;
    }

    function batchWithdraw(uint256[] calldata tokenIds) external {
        bool isApproved = getIsApproved();
        for (uint256 i = tokenIds.length; i > 0; --i) {
            withdraw(isApproved, tokenIds[i - 1]);
        }
    }

    function withdrawAll() external {
        bool isApproved = getIsApproved();
        for (uint256 i = lockDealNFT.balanceOf(msg.sender); i > 0; --i) {
            uint256 token = lockDealNFT.tokenOfOwnerByIndex(msg.sender, i - 1);
            withdrawIfNoEmpty(isApproved, token);
        }
    }

    function withdrawAll(address[] calldata tokenFilter) external {
        bool isApproved = getIsApproved();
        for (uint256 i = lockDealNFT.balanceOf(msg.sender, tokenFilter); i > 0; --i) {
            uint256 token = lockDealNFT.tokenOfOwnerByIndex(msg.sender, i - 1, tokenFilter);
            withdrawIfNoEmpty(isApproved, token);
        }
    }

    function checkData(bool isApproved, uint256 poolId) internal view {
        require(lockDealNFT.ownerOf(poolId) == msg.sender, "BatchWithdraw: not owner");
        require(isApproved || lockDealNFT.getApproved(poolId) == address(this), "BatchWithdraw: not approved");
    }

    function getIsApproved() internal view returns (bool isApproved) {
        isApproved = lockDealNFT.isApprovedForAll(msg.sender, address(this));
    }

    function withdraw(bool isApproved, uint256 poolId) internal {
        checkData(isApproved, poolId);
        lockDealNFT.safeTransferFrom(msg.sender, address(lockDealNFT), poolId); // transfer to lockDealNFT = withdraw
    }

    function withdrawIfNoEmpty(bool isApproved, uint256 poolId) internal {
        if (lockDealNFT.getWithdrawableAmount(poolId) > 0) {
            withdraw(isApproved, poolId);
        }
    }
}
