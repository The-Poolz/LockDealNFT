// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "./TimedLockDealModifiers.sol";

contract TimedLockDealProvider is ERC20Helper, TimedLockDealModifiers {
    constructor(address nft, address provider) {
        dealProvider = BaseLockDealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    /// params[0] = leftAmount
    /// params[1] = startTime
    /// params[2] = finishTime
    /// params[3] = startAmount
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        require(
            params[2] >= params[1],
            "Finish time should be greater than start time"
        );
        poolId = lockDealNFT.mint(owner);
        _registerPool(poolId, params);
        if (!dealProvider.dealProvider().nftContract().approvedProviders(msg.sender)) {
            TransferInToken(token, msg.sender, params[0]);
        }
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
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public onlyProvider {
        (, uint256 leftAmount) = dealProvider.dealProvider().poolIdToDeal(
            oldPoolId
        );
        (
            uint256 newPoolLeftAmount,
            uint256 newPoolStartAmount
        ) = _calcSplit(oldPoolId, leftAmount, splitAmount);
        dealProvider.split(oldPoolId, newPoolId, newPoolLeftAmount);
        poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId].finishTime;
    }

    function _calcSplit(
        uint256 poolId,
        uint256 leftAmount,
        uint256 splitAmount
    ) internal view returns (uint256 newLeftAmount, uint256 newStartAmount) {
        uint256 ratio = _calcRatio(splitAmount, leftAmount);
        newLeftAmount = _calcAmountFromRatio(poolIdToTimedDeal[poolId].startAmount, ratio);
        newStartAmount = _calcAmountFromRatio(leftAmount, ratio);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return currentParamsTargetLenght + dealProvider.currentParamsTargetLenght();
    }

    function _calcRatio(uint256 amount, uint256 totalAmount) internal pure returns (uint256) {
        return (amount * 10 ** 18) / totalAmount;
    }

    function _calcAmountFromRatio(uint256 amount, uint256 ratio) internal pure returns (uint256) {
        return (amount * ratio) / 10 ** 18;
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        public
        onlyProvider
    {
        _registerPool(poolId, params);
    }

    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        internal
        validParamsLength(params.length, getParametersTargetLenght())
    {
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[3];
        dealProvider.registerPool(poolId, params);
    }
}
