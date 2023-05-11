// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";
import "./IBaseLockEvents.sol";

contract BaseLockDealProvider is DealProvider, IBaseLockEvents {
    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime
    ) external {
        _createNewPool(to, tokenAddress, amount, startTime);
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
            itemId,
            itemIdToDeal[itemId].tokenAddress,
            withdrawnAmount,
            nftContract.ownerOf(itemId)
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
            deal.tokenAddress,
            splitAmount,
            deal.startTime
        );
        emit PoolSplit(
            itemId,
            newPoolId,
            deal.startAmount,
            splitAmount,
            nftContract.ownerOf(itemId),
            newOwner
        );
    }
}
