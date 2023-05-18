// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./DealProviderModifiers.sol";
import "../interface/ICustomLockedDeal.sol";

abstract contract DealProvider is
    DealProviderModifiers,
    ERC20Helper,
    ICustomLockedDeal
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function createNewPool(
        address owner,
        address token,
        uint256 amount
    ) public returns (uint256 poolId) {
        poolId = nftContract.totalSupply();
        poolIdToDeal[poolId] = Deal(token, amount);
        nftContract.mint(owner);
        if (!nftContract.approvedProviders(msg.sender)) {
            TransferInToken(token, msg.sender, amount);
            emit NewPoolCreated(
                BasePoolInfo(poolId, owner),
                Deal(token, amount)
            );
        }
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        if (poolIdToDeal[poolId].leftAmount >= 0) {
            withdrawnAmount = poolIdToDeal[poolId].leftAmount;
            poolIdToDeal[poolId].leftAmount = 0;
            TransferToken(
                poolIdToDeal[poolId].token,
                nftContract.ownerOf(poolId),
                withdrawnAmount
            );
            emit TokenWithdrawn(
                BasePoolInfo(poolId, nftContract.ownerOf(poolId)),
                withdrawnAmount,
                poolIdToDeal[poolId].leftAmount
            );
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    )
        public
        override
        notZeroAmount(splitAmount)
        notZeroAddress(newOwner)
        onlyPoolOwner(poolId)
        invalidSplitAmount(poolIdToDeal[poolId].leftAmount, splitAmount)
    {
        Deal storage deal = poolIdToDeal[poolId];
        deal.leftAmount -= splitAmount;
        uint256 newPoolId = createNewPool(newOwner, deal.token, splitAmount);
        emit PoolSplit(
            BasePoolInfo(poolId, nftContract.ownerOf(poolId)),
            BasePoolInfo(newPoolId, newOwner),
            splitAmount
        );
    }

    function getDeal(uint256 poolId) public view returns (address, uint256) {
        return (poolIdToDeal[poolId].token, poolIdToDeal[poolId].leftAmount);
    }
}
