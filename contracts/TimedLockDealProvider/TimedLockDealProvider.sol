// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "./TimedLockDealModifiers.sol";

contract TimedLockDealProvider is ERC20Helper, TimedLockDealModifiers {
    constructor(address provider) {
        dealProvider = BaseLockDealProvider(provider);
    }

    /// params[0] = amount
    /// params[1] = startTime
    /// params[2] = finishTime
    /// params[3] = withdrawnAmount
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        require(
            params[2] >= params[1],
            "Finish time should be greater than start time"
        );
        poolId = dealProvider.createNewPool(owner, token, params);
        poolIdToTimedDeal[poolId] = TimedDeal(params[2], params[3]);
    }

    function withdraw(uint256 poolId) public returns (uint256 withdrawnAmount) {
        //if ((msg.sender == dealProvider.nftContract().ownerOf(poolId))) {}
        //Deal storage deal = itemIdToDeal[itemId];
        // TimedDeal storage timedDeal = poolIdToTimedDeal[itemId];
        // require(
        //     msg.sender == nftContract.ownerOf(itemId),
        //     "Not the owner of the item"
        // );
        // require(
        //     block.timestamp >= deal.startTime,
        //     "Withdrawal time not reached"
        // );
        // if (block.timestamp >= timedDeal.finishTime) {
        //     withdrawnAmount = deal.startAmount;
        // } else {
        //     uint256 elapsedTime = block.timestamp - deal.startTime;
        //     uint256 totalTime = timedDeal.finishTime - deal.startTime;
        //     uint256 availableAmount = (deal.startAmount * elapsedTime) /
        //         totalTime;
        //     withdrawnAmount = availableAmount - timedDeal.withdrawnAmount;
        // }
        // require(withdrawnAmount > 0, "No amount left to withdraw");
        // timedDeal.withdrawnAmount += withdrawnAmount;
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) public {
        (address token, uint256 startAmount) = dealProvider
            .dealProvider()
            .poolIdToDeal(poolId);
        (
            uint256 leftAmount,
            uint256 withdrawnAmount,
            uint256 newPoolLeftAmount,
            uint256 newPoolWithdrawnAmount
        ) = _calculateSplit(poolId, startAmount, splitAmount);
        uint256 startTime = dealProvider.startTimes(poolId);
        registerPool(
            poolId,
            getParams(
                leftAmount,
                startTime,
                poolIdToTimedDeal[poolId].finishTime,
                withdrawnAmount
            )
        );
        createNewPool(
            newOwner,
            token,
            getParams(
                newPoolLeftAmount,
                startTime,
                poolIdToTimedDeal[poolId].finishTime,
                newPoolWithdrawnAmount
            )
        );
    }

    function _calculateSplit(
        uint256 poolId,
        uint256 startAmount,
        uint256 splitAmount
    ) internal view returns (uint256, uint256, uint256, uint256) {
        uint256 ratio = (splitAmount * 10 ** 18) / startAmount;
        uint256 tempNewPoolLeftAmount = (poolIdToTimedDeal[poolId]
            .withdrawnAmount * ratio) / 10 ** 18;
        uint256 tempNewPoolWithdrawnAmount = (startAmount * ratio) / 10 ** 18;
        return (
            startAmount - tempNewPoolLeftAmount,
            startAmount - tempNewPoolWithdrawnAmount,
            tempNewPoolLeftAmount,
            tempNewPoolWithdrawnAmount
        );
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        public
        onlyProvider
        validParamsLength(params.length, getParametersTargetLenght())
    {
        poolIdToTimedDeal[poolId].finishTime = params[2];
        dealProvider.registerPool(poolId, params);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return
            currentParamsTargetLenght +
            dealProvider.currentParamsTargetLenght();
    }
}
