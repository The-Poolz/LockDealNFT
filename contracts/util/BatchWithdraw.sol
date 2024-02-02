// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INFTView.sol";

contract BatchWithdraw {
    ILockDealNFTViews public lockDealNFT;

    constructor(ILockDealNFTViews _lockDealNFT) {
        lockDealNFT = _lockDealNFT;
    }

    ///@dev Use this function to withdraw the tokens from the user
    ///@param tokenIds - array of token ids - must be owned by the user
    function batchWithdraw(uint256[] calldata tokenIds) external {
        bool isApproved = _getIsApproved();
        for (uint256 i = tokenIds.length; i > 0; ) {
            _withdrawIfNoEmpty(isApproved, tokenIds[--i]);
        }
    }

    ///@dev Use this function to refund the tokens to the user
    ///@param tokenIds - array of token ids - must be owned by the user and be RefundProvider
    function batchRefund(uint256[] calldata tokenIds) external {
        bool isApproved = _getIsApproved();
        require(isApproved, "BatchWithdraw: not approved");
        for (uint256 i = tokenIds.length; i > 0; ) {
            uint256 token = tokenIds[--i];
            _withdraw(_refund(token));
        }
    }
    ///@dev withdraw all tokens from the user that are not empty
    ///@notice This is very expensive function, use it only if you know what you are doing
    function withdrawAll() external {
        bool isApproved = _getIsApproved();
        for (uint256 i = lockDealNFT.balanceOf(msg.sender); i > 0; ) {
            uint256 token = lockDealNFT.tokenOfOwnerByIndex(msg.sender, --i);
            _withdrawIfNoEmpty(isApproved, token);
        }
    }

    ///@dev withdraw all tokens from the user that are not empty and match the filter
    ///@param tokenFilter - filter by token address
    ///@notice This is very expensive function, use it only if you know what you are doing
    function withdrawAll(address[] calldata tokenFilter) external {
        bool isApproved = _getIsApproved();
        for (uint256 i = lockDealNFT.balanceOf(msg.sender, tokenFilter); i > 0; ) {
            uint256 token = lockDealNFT.tokenOfOwnerByIndex(msg.sender, --i, tokenFilter);
            _withdrawIfNoEmpty(isApproved, token);
        }
    }

    function _checkData(bool isApproved, uint256 poolId) internal view {
        require(lockDealNFT.ownerOf(poolId) == msg.sender, "BatchWithdraw: not owner");
        require(isApproved || lockDealNFT.getApproved(poolId) == address(this), "BatchWithdraw: not approved");
    }

    function _getIsApproved() internal view returns (bool isApproved) {
        isApproved = lockDealNFT.isApprovedForAll(msg.sender, address(this));
    }

    function _withdraw(bool isApproved, uint256 poolId) internal {
        _checkData(isApproved, poolId);
        _withdraw(poolId);
    }

    function _withdraw(uint256 poolId) internal {
        lockDealNFT.safeTransferFrom(msg.sender, address(lockDealNFT), poolId); // transfer to lockDealNFT = withdraw
    }

    function _refund(uint256 poolId) internal returns (uint256 newPoolId) {
        IProvider refundProvider = _getProvider(poolId);
        require(_isRefundProvider(refundProvider), "BatchWithdraw: must be RefundProvider");
        newPoolId = lockDealNFT.totalSupply();
        lockDealNFT.safeTransferFrom(msg.sender, address(refundProvider), poolId); // transfer to refundProvider = refund
    }

    function _withdrawIfNoEmpty(bool isApproved, uint256 poolId) internal {
        if (lockDealNFT.getWithdrawableAmount(poolId) > 0) {
            _withdraw(isApproved, poolId);
        }
    }

    function _isRefundProvider(IProvider provider) internal view returns (bool isRefundProvider) {
        isRefundProvider = keccak256(bytes(provider.name())) == keccak256(bytes("RefundProvider"));
    }

    function _getProvider(uint256 poolId) internal view returns (IProvider provider) {
        provider = lockDealNFT.poolIdToProvider(poolId);
    }
}
