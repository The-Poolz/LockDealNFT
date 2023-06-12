// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";
import "../Provider/BasicProvider.sol";

contract TimedDealProvider is BasicProvider, TimedProviderState {
    /**
     * @dev Contract constructor.
     * @param nft The address of the LockDealNFT contract.
     * @param provider The address of the LockProvider contract.
     */
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        dealProvider = LockDealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = dealProvider.withdraw(poolId, amount);
    }

    function getWithdrawableAmount(uint256 poolId) public view returns (uint256) {
        (, uint256[] memory params) = getData(poolId);
        uint256 leftAmount = params[0];
        uint256 startTime = params[1];
        uint256 finishTime = params[2];
        uint256 startAmount = params[3];

        if (block.timestamp < startTime) return 0;
        if (finishTime < block.timestamp) return leftAmount;

        uint256 totalPoolDuration = finishTime - startTime;
        uint256 timePassed = block.timestamp - startTime;
        uint256 debitableAmount = (startAmount * timePassed) / totalPoolDuration;
        return debitableAmount - (startAmount - leftAmount);
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

    ///@param params[0] = leftAmount
    ///@param params[1] = startTime
    ///@param params[2] = finishTime
    ///@param params[3] = startAmount
    function _registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) internal override {
        require(
            params[2] >= params[1],
            "Finish time should be greater than start time"
        );
        require(
            params[0] == params[3],
            "Start amount should be equal to left amount"
        );
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[3];
        dealProvider.registerPool(poolId, owner, token, params);
    }

    function getData(uint256 poolId) public view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory lockDealProviderParams;
        (poolInfo, lockDealProviderParams) = dealProvider.getData(poolId);

        params = new uint256[](4);
        params[0] = lockDealProviderParams[0];  // leftAmount
        params[1] = lockDealProviderParams[1];  // startTime
        params[2] = poolIdToTimedDeal[poolId].finishTime; // finishTime
        params[3] = poolIdToTimedDeal[poolId].startAmount; // startAmount
    }

    function currentParamsTargetLenght() public override view returns (uint256) {
        return 2 + dealProvider.currentParamsTargetLenght();
    }
}