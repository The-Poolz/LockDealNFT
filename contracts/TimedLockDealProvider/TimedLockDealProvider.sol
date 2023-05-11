// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseProvider/BaseLockDealProvider.sol";

contract TimedLockDealProvider is BaseLockDealProvider {
    struct TimedDeal {
        uint256 finishTime;
        uint256 debitedAmount;
    }

    mapping(uint256 => TimedDeal) public itemIdToTimedDeal;

    constructor(address _nftContract) BaseLockDealProvider(_nftContract) {}

    function createNewPool(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) external returns(uint256 newItemId) {
        require(
            finishTime > startTime,
            "Finish time should be greater than start time"
        );
        TransferInToken(tokenAddress, tx.origin, amount);
        newItemId = _createNewPool(to, tokenAddress, amount, startTime);
        itemIdToTimedDeal[newItemId] = TimedDeal(finishTime, 0);
    }

     function createMassPool(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory startTimes,
        uint256[] memory finishTimes,
        uint256[] memory amounts
    ) external virtual {
        require(amounts.length == startTimes.length 
        && recipients.length == startTimes.length
        && finishTimes.length == startTimes.length, "Invalid input");
        TransferInToken(tokenAddress, tx.origin, Array.getArraySum(amounts));
        for (uint256 i = 0; i < startTimes.length; i++) {
            uint itemId = _createNewPool(recipients[i], tokenAddress, amounts[i], startTimes[i]);
            itemIdToTimedDeal[itemId] = TimedDeal(finishTimes[i], 0);
        }
    }

    function createPoolsWrtTime(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory startTimes,
        uint256[] memory finishTimes,
        uint256[] memory amounts
    ) external virtual {
        require(amounts.length == recipients.length
        && startTimes.length == finishTimes.length, "Invalid input");
        TransferInToken(
            tokenAddress,
            tx.origin,
            Array.getArraySum(amounts) * startTimes.length
        );
        for (uint256 i = 0; i < startTimes.length; i++) {
            for(uint256 j = 0; j < amounts.length; j++) {
                uint itemId = _createNewPool(recipients[i], tokenAddress, amounts[j], startTimes[i]);
                itemIdToTimedDeal[itemId] = TimedDeal(finishTimes[i], 0);
            }
        }
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
        // denial of refund attack will be handled by the MainCoinManager contract
        // require(
        //     msg.sender == nftContract.ownerOf(itemId),
        //     "Not the owner of the item"
        // );
        if(deal.startTime > block.timestamp) return 0;
        if (block.timestamp >= timedDeal.finishTime) {
            withdrawnAmount = deal.amount - timedDeal.debitedAmount;
        } else {
            uint256 elapsedTime = block.timestamp - deal.startTime;
            uint256 totalTime = timedDeal.finishTime - deal.startTime;
            uint256 withdrawableAmount = (deal.amount * elapsedTime) / totalTime;
            withdrawnAmount = withdrawableAmount - timedDeal.debitedAmount;
        }
        timedDeal.debitedAmount += withdrawnAmount;
        TransferToken(deal.tokenAddress, nftContract.ownerOf(itemId), withdrawnAmount);
    }
}
