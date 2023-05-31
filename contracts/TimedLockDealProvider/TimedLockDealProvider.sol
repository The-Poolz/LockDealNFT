// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "../Provider/ProviderModifiers.sol";
import "../interface/IProvider.sol";

contract TimedLockDealProvider is
    ProviderModifiers,
    TimedProviderState,
    IProvider
{
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
    )
        public
        notZeroAddress(owner)
        notZeroAddress(token)
        returns (uint256 poolId)
    {
        require(
            params[2] >= params[1],
            "Finish time should be greater than start time"
        );
        require(
            params[0] == params[3],
            "Start amount should be equal to left amount"
        );
        poolId = lockDealNFT.mint(owner, token);
        _registerPool(poolId, params);
        emit NewPoolCreated(BasePoolInfo(poolId, owner, token), params);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount) {
        withdrawnAmount = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public onlyProvider returns (uint256 withdrawnAmount) {
        withdrawnAmount = dealProvider.withdraw(poolId, amount);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal returns (uint256 withdrawnAmount) {
        withdrawnAmount = dealProvider.withdraw(poolId, amount);
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
        uint256 newPoolStartAmount = poolIdToTimedDeal[oldPoolId].startAmount -
            splitAmount;
        poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId]
            .finishTime;
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

    function getData(uint256 poolId) external override view returns (BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory baseLockDealProviderParams;
        (poolInfo, baseLockDealProviderParams) = dealProvider.getData(poolId);

        params = new uint256[](4);
        params[0] = baseLockDealProviderParams[0];  // leftAmount
        params[1] = baseLockDealProviderParams[1];  // startTime
        params[2] = poolIdToTimedDeal[poolId].finishTime; // finishTime
        params[3] = poolIdToTimedDeal[poolId].startAmount; // startAmount
    }
}
