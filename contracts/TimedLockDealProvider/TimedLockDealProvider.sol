// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";

contract TimedLockDealProvider is DealProvider {
    struct TimedDeal {
        uint256 finishTime;
        uint256 withdrawnAmount;
    }

    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;

    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) external {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        _createNewPool(to, tokenAddress, amount, startTime, finishTime);
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
        Deal storage deal = itemIdToDeal[itemId];
        TimedDeal storage timedDeal = poolIdToTimedDeal[itemId];
        require(
            msg.sender == nftContract.ownerOf(itemId),
            "Not the owner of the item"
        );
        require(
            block.timestamp >= deal.startTime,
            "Withdrawal time not reached"
        );
        if (block.timestamp >= timedDeal.finishTime) {
            withdrawnAmount = deal.startAmount;
        } else {
            uint256 elapsedTime = block.timestamp - deal.startTime;
            uint256 totalTime = timedDeal.finishTime - deal.startTime;
            uint256 availableAmount = (deal.startAmount * elapsedTime) /
                totalTime;
            withdrawnAmount = availableAmount - timedDeal.withdrawnAmount;
        }
        require(withdrawnAmount > 0, "No amount left to withdraw");
        timedDeal.withdrawnAmount += withdrawnAmount;
    }

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external virtual override {
        Deal storage deal = itemIdToDeal[itemId];
        TimedDeal storage timedDeal = poolIdToTimedDeal[itemId];
        uint256 leftAmount = deal.startAmount - timedDeal.withdrawnAmount;
        require(
            leftAmount >= splitAmount,
            "Split amount exceeds the available amount"
        );
        uint256 ratio = (splitAmount * 10 ** 18) / leftAmount;
        uint256 newPoolDebitedAmount = (timedDeal.withdrawnAmount * ratio) / 10 ** 18;
        uint256 newPoolStartAmount = (deal.startAmount * ratio) / 10 ** 18;
        deal.startAmount -= newPoolStartAmount;
        timedDeal.withdrawnAmount -= newPoolDebitedAmount;
        uint256 newPoolId = _createNewPool(
            newOwner,
            deal.tokenAddress,
            newPoolStartAmount,
            deal.startTime,
            timedDeal.finishTime
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

    function _createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) internal returns (uint256 newItemId) {
        newItemId = _createNewPool(to, tokenAddress, amount, startTime);
        poolIdToTimedDeal[newItemId] = TimedDeal(finishTime, 0);
    }
}
