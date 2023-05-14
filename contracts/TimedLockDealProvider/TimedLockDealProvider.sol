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
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime,
        address owner
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
    {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        uint256 poolId = _createNewPool(
            token,
            amount,
            startTime,
            finishTime,
            owner
        );
        TransferInToken(token, msg.sender, amount);
        uint256[] memory params = new uint256[](3);
        params[0] = amount;
        params[1] = startTime;
        params[2] = finishTime;
        emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), params); //Line 41-45 will be replaced with the next line after PR #19 is merged
        //emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), GetParams(amount, startTime, finishTime)); //GetParams is in PR #19
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
        uint256 newPoolDebitedAmount = (timedDeal.withdrawnAmount * ratio) /
            10 ** 18;
        uint256 newPoolStartAmount = (deal.startAmount * ratio) / 10 ** 18;
        deal.startAmount -= newPoolStartAmount;
        timedDeal.withdrawnAmount -= newPoolDebitedAmount;
        uint256 newPoolId = _createNewPool(
            deal.token,
            newPoolStartAmount,
            deal.startTime,
            timedDeal.finishTime,
            newOwner
        );
        emit PoolSplit(
            createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
            createBasePoolInfo(newPoolId, newOwner, deal.token),
            splitAmount
        );
    }

    function _createNewPool(
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime,
        address owner
    ) internal returns (uint256 newItemId) {
        newItemId = _createNewPool(token, amount, startTime, owner);
        poolIdToTimedDeal[newItemId] = TimedDeal(finishTime, 0);
    }
}
