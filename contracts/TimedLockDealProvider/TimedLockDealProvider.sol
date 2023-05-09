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

    function mint(
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

        _mint(to, tokenAddress, amount, startTime);

        uint256 newItemId = nftContract.totalSupply();
        itemIdToTimedDeal[newItemId] = TimedDeal(finishTime, 0);
    }

    function withdraw(uint256 itemId) external override {
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

        uint256 withdrawalAmount;
        if (block.timestamp >= timedDeal.finishTime) {
            withdrawalAmount = deal.amount;
        } else {
            uint256 elapsedTime = block.timestamp - deal.startTime;
            uint256 totalTime = timedDeal.finishTime - deal.startTime;
            uint256 availableAmount = (deal.amount * elapsedTime) / totalTime;

            withdrawalAmount = availableAmount - timedDeal.withdrawnAmount;
        }

        require(withdrawalAmount > 0, "No amount left to withdraw");

        // Implement the logic for transferring tokens from this contract to msg.sender
        // For example, if it's an ERC20 token, use the ERC20 contract's transfer function

        timedDeal.withdrawnAmount += withdrawalAmount;
    }
}
