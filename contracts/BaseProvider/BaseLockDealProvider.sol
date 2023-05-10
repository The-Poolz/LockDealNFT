// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";
import "./IBaseLockEvents.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is
    ICustomLockedDeal,
    IBaseLockEvents,
    BaseLockDealModifiers,
    ERC20Helper
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

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
        notZeroAmount(itemIdToDeal[itemId].amount)
        validTime(itemIdToDeal[itemId].startTime)
        returns (uint256 withdrawnAmount)
    {
        withdrawnAmount = itemIdToDeal[itemId].amount;
        itemIdToDeal[itemId].amount = 0;
        TransferToken(
            itemIdToDeal[itemId].tokenAddress,
            nftContract.ownerOf(itemId),
            withdrawnAmount
        );
        emit TokenWithdrawn(
            itemId,
            itemIdToDeal[itemId].tokenAddress,
            withdrawnAmount,
            nftContract.ownerOf(itemId)
        );
    }

    function split(
        address to,
        uint256 itemId,
        uint256 splitAmount
    )
        external
        virtual
        override
        notZeroAmount(splitAmount)
        onlyOwnerOrAdmin(itemId)
    {
        Deal storage deal = itemIdToDeal[itemId];
        require(
            deal.amount >= splitAmount,
            "Split amount exceeds the available amount"
        );
        deal.amount -= splitAmount;
        _createNewPool(to, deal.tokenAddress, splitAmount, deal.startTime);
    }

    function _createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime
    ) internal returns (uint256 newItemId) {
        nftContract.mint(to);
        newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(tokenAddress, amount, startTime);
        emit NewPoolCreated(newItemId, tokenAddress, startTime, amount, to);
    }
}
