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
        address owner,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        poolId = _createNewPool(
            owner,
            token,
            GetParams(amount, startTime, finishTime)
        );
        TransferInToken(token, msg.sender, amount);
        emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), GetParams(amount, startTime, finishTime));
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
            newOwner,
            deal.token,
            GetParams(splitAmount, deal.startTime, timedDeal.finishTime)
        );
        emit PoolSplit(
            createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
            createBasePoolInfo(newPoolId, newOwner, deal.token),
            splitAmount
        );
    }

    function GetParams(
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](3);
        params[0] = amount;
        params[1] = startTime;
        params[2] = finishTime;
    }

    function _createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) internal override validParams(params,3) returns (uint256 newItemId) {
        // Assuming params[0] is amount, params[1] is startTime, params[2] is finishTime
        newItemId = super._createNewPool(
            owner,
            token,
            super.GetParams(params[0], params[1])
        );
        poolIdToTimedDeal[newItemId] = TimedDeal(params[2], 0);
    }
}
