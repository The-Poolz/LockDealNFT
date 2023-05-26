// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "./TimedLockDealModifiers.sol";
import "../interface/IProvider.sol";

contract TimedLockDealProvider is TimedLockDealModifiers, IProvider {
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
        poolId = lockDealNFT.mint(owner, token);
        _registerPool(poolId, params);
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
        dealProvider.split(oldPoolId, newPoolId, splitAmount);
        uint256 newPoolStartAmount = poolIdToTimedDeal[oldPoolId].startAmount - splitAmount;
        poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId].finishTime;
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return
            currentParamsTargetLenght +
            dealProvider.currentParamsTargetLenght();
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    ) public onlyProvider {
        _registerPool(poolId, params);
    }

    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal validParamsLength(params.length, getParametersTargetLenght()) {
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[3];
        dealProvider.registerPool(poolId, params);
    }
}
