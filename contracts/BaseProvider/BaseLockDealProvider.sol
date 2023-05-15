// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";

contract BaseLockDealProvider is DealProvider {
    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime      
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        poolId = _createNewPool(owner,token,GetParams(amount,startTime));
        TransferInToken(token, msg.sender, amount);
        emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), GetParams(amount, startTime));
    }

    function withdraw(
        uint256 itemId
    )
        external
        virtual
        override
        onlyOwnerOrAdmin(itemId)
        notZeroAmount(itemIdToDeal[itemId].startAmount)
        validTime(itemIdToDeal[itemId].startTime)
        returns (uint256 withdrawnAmount)
    {
        withdrawnAmount = itemIdToDeal[itemId].startAmount;
        itemIdToDeal[itemId].startAmount = 0;
        _withdraw(itemId, withdrawnAmount);
        emit TokenWithdrawn(
            createBasePoolInfo(
                itemId,
                nftContract.ownerOf(itemId),
                itemIdToDeal[itemId].token
            ),
            withdrawnAmount,
            itemIdToDeal[itemId].startAmount
        );
    }

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    )
        external
        virtual
        override
        notZeroAmount(splitAmount)
        notZeroAddress(newOwner)
        onlyOwnerOrAdmin(itemId)
    {
        Deal storage deal = itemIdToDeal[itemId];
        require(
            deal.startAmount >= splitAmount,
            "Split amount exceeds the available amount"
        );
        deal.startAmount -= splitAmount;
        uint256 newPoolId = _createNewPool(
            newOwner,
            deal.token,
            GetParams(splitAmount, deal.startTime) 
        );
        emit PoolSplit(
            createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
            createBasePoolInfo(newPoolId, newOwner, deal.token),
            splitAmount
        );
    }
}
