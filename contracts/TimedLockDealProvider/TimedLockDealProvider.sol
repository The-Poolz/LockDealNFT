// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseProvider/BaseLockDealProvider.sol";

contract TimedLockDealProvider is BaseLockDealProvider {
    struct TimedDeal {
        uint256 finishTime;
        uint256 withdrawnAmount;
    }

    mapping(uint256 => TimedDeal) public itemIdToTimedDeal;

    constructor(address _nftContract) BaseLockDealProvider(_nftContract) {}

    function createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) external {
        require(
            finishTime > startTime,
            "Finish time should be greater than start time"
        );

        _createNewPool(to, tokenAddress, amount, startTime);

        uint256 newItemId = nftContract.totalSupply();
        itemIdToTimedDeal[newItemId] = TimedDeal(finishTime, 0);
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
        Deal storage deal = itemIdToDeal[itemId];
        TimedDeal storage timedDeal = itemIdToTimedDeal[itemId];

        require(
            msg.sender == nftContract.ownerOf(itemId),
            "Not the owner of the item"
        );
        require(
            block.timestamp >= deal.startTime,
            "Withdrawal time not reached"
        );
        if (block.timestamp >= timedDeal.finishTime) {
            withdrawnAmount = deal.amount;
        } else {
            uint256 elapsedTime = block.timestamp - deal.startTime;
            uint256 totalTime = timedDeal.finishTime - deal.startTime;
            uint256 availableAmount = (deal.amount * elapsedTime) / totalTime;

            withdrawnAmount = availableAmount - timedDeal.withdrawnAmount;
        }

        require(withdrawnAmount > 0, "No amount left to withdraw");

        // Implement the logic for transferring tokens from this contract to msg.sender
        // For example, if it's an ERC20 token, use the ERC20 contract's transfer function

        timedDeal.withdrawnAmount += withdrawnAmount;
    }
}
