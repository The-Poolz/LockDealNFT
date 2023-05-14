// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";
import "./ITimedLockEvents.sol";

contract TimedLockDealProvider is DealProvider, ITimedLockEvents, IInitiator {
    struct TimedDeal {
        uint256 finishTime;
        uint256 withdrawnAmount;
    }

    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;

    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) external {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        _initiateNewPool(token, amount, startTime, finishTime, owner);
        TransferInToken(token, owner, amount);
    }

    function initiate(
        address owner,
        address token,
        uint[] memory params
    ) external override returns (uint256 poolId) {
        require(params.length == 3, "Incorrect number of parameters");
        poolId = _initiateNewPool(
            owner,
            token,
            params[0],
            params[1],
            params[2]
        );
    }

    function _initiateNewPool(
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime,
        address owner
    )
        internal
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        uint256 poolId = _createNewPool(
            owner,
            token,
            amount,
            startTime,
            finishTime          
        );
        emit NewPoolCreated(
            poolId,
            token,
            startTime,
            finishTime,
            amount,
            0,
            owner
        );
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
            itemId,
            newPoolId,
            deal.startAmount,
            splitAmount,
            nftContract.ownerOf(itemId),
            newOwner
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
