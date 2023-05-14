// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";

contract BaseLockDealProvider is DealProvider {
    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address token,
        uint256 amount,
        uint256 startTime,
        address owner
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
    {
        uint256 poolId = _createNewPool(token, amount, startTime, owner);
        TransferInToken(token, msg.sender, amount);
        uint256[] memory params = new uint256[](2);
        params[0] = amount;
        params[1] = startTime;
        emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), params); //Line 26-29 will be replaced with the next line after PR #19 is merged
        //emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), GetParams(amount, startTime)); //GetParams is in Pr #19
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
            deal.token,
            splitAmount,
            deal.startTime,
            newOwner
        );
        emit PoolSplit(
            createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
            createBasePoolInfo(newPoolId, newOwner, deal.token),
            splitAmount
        );
    }
}
