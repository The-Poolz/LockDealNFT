// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "./TimedLockDealModifiers.sol";
import "../interface/IProvider.sol";

contract TimedLockDealProvider is TimedLockDealModifiers, IProvider {
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
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
        require(
            params[0] == params[3],
            "Start amount should be equal to left amount"
        );
        _registerPool(poolId, token, params);
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);
    }

    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        if (lockDealNFT.approvedProviders(msg.sender)) {
            withdrawnAmount = (block.timestamp >=
                poolIdToTimedDeal[poolId].finishTime)
                ? dealProvider.withdraw(poolId)
                : dealProvider.withdraw(poolId, getWithdrawableAmount(poolId));
        }
    }

    function getWithdrawableAmount(
        uint256 poolId
    ) public view returns (uint256) {
        uint256 startTime = dealProvider.startTimes(poolId);
        if (block.timestamp < startTime) return 0;
        (, uint256 leftAmount) = dealProvider.dealProvider().poolIdToDeal(
            poolId
        );
        if (poolIdToTimedDeal[poolId].finishTime < block.timestamp)
            return leftAmount;
        uint256 totalPoolDuration = poolIdToTimedDeal[poolId].finishTime - startTime;
        uint256 timePassed = block.timestamp - startTime;
        uint256 debitableAmount = (poolIdToTimedDeal[poolId].startAmount * timePassed) / totalPoolDuration;
        return debitableAmount - (poolIdToTimedDeal[poolId].startAmount - leftAmount);
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public onlyProvider {
        (, uint256 leftAmount) = dealProvider.dealProvider().poolIdToDeal(
            oldPoolId
        );
        (uint256 newPoolLeftAmount, uint256 newPoolStartAmount) = _calcSplit(
            oldPoolId,
            leftAmount,
            splitAmount
        );
        dealProvider.split(oldPoolId, newPoolId, newPoolLeftAmount);
        poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId]
            .finishTime;
    }

    function _calcSplit(
        uint256 poolId,
        uint256 leftAmount,
        uint256 splitAmount
    ) internal view returns (uint256 newLeftAmount, uint256 newStartAmount) {
        uint256 ratio = _calcRatio(splitAmount, leftAmount);
        newLeftAmount = _calcAmountFromRatio(
            poolIdToTimedDeal[poolId].startAmount,
            ratio
        );
        newStartAmount = _calcAmountFromRatio(leftAmount, ratio);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return
            currentParamsTargetLenght +
            dealProvider.currentParamsTargetLenght();
    }

    function _calcRatio(
        uint256 amount,
        uint256 totalAmount
    ) internal pure returns (uint256) {
        return (amount * 10 ** 18) / totalAmount;
    }

    function _calcAmountFromRatio(
        uint256 amount,
        uint256 ratio
    ) internal pure returns (uint256) {
        return (amount * ratio) / 10 ** 18;
    }

    function registerPool(
        uint256 poolId,
        address token,
        uint256[] memory params
    ) public onlyProvider {
        _registerPool(poolId, token, params);
    }

    function _registerPool(
        uint256 poolId,
        address token,
        uint256[] memory params
    ) internal validParamsLength(params.length, getParametersTargetLenght()) {
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[3];
        dealProvider.registerPool(poolId, token, params);
    }
}
