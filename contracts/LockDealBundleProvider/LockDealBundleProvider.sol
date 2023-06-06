// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderState.sol";
import "../Provider/ProviderModifiers.sol";
import "../interface/IProvider.sol";

contract LockDealBundleProvider is
    ProviderModifiers,
    TimedProviderState,
    IProvider
{
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        timedDealProvider = TimedDealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    ///@param params[0] = leftAmount
    ///@param params[1] = startTime
    ///@param params[2] = finishTime
    ///@param params[3] = startAmount
    ///@param params[4] = totalAmount
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        // amount for LockDealProvider = `totalAmount` - `startAmount`
        // amount for TimedDealProvider = `startAmount`

        // mint the NFT owned by the BunderDealProvider on LockDealProvider for `totalAmount` - `startAmount` token amount
        // mint the NFT owned by the BunderDealProvider on TimedDealProvider for `startAmount` token amount
        // mint the NFT owned by the owner on LockDealBundleProvider for `totalAmount` token transfer amount

        // To optimize the token transfer (for 1 token transfer)
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on LockDealProvider
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on TimedDealProvider
        // mint the NFT owned by the owner with `totalAmount` token transfer amount on LockDealBundleProvider

        require(
            params[4] > params[3],
            "Total amount should be greater than start amount"
        );

        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
        LockDealProvider lockDealProvider = timedDealProvider.dealProvider();
        uint256 poolIdForLockDealProvider = lockDealNFT.mint(address(lockDealProvider), token, msg.sender, 0);

        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
        lockDealNFT.mint(address(timedDealProvider), token, msg.sender, 0);

        // create a new pool owned by teh owner with `totalAmount` token trasnfer amount
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[4]);
        _registerPool(poolId, owner, token, params, poolIdForLockDealProvider);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = timedDealProvider.withdraw(poolId, amount);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = timedDealProvider.withdraw(poolId, amount);
    }

    function getWithdrawableAmount(
        uint256 poolId
    ) public view returns (uint256) {
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
        timedDealProvider.split(oldPoolId, newPoolId, splitAmount);
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
            timedDealProvider.getParametersTargetLenght();
    }

    function registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params,
        uint256 firstSubPoolId
    ) public onlyProvider {
        _registerPool(poolId, owner, token, params, firstSubPoolId);
    }

    function _registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params,
        uint256 firstSubPoolId
    ) internal validParamsLength(params.length, getParametersTargetLenght()) {
        poolIdToLockDealBundle[poolId].totalAmount = params[4];
        poolIdToLockDealBundle[poolId].firstSubPoolId = firstSubPoolId;
        timedDealProvider.registerPool(poolId, owner, token, params);
    }

    function getData(uint256 poolId) public override view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory timedDealProviderParams;
        (poolInfo, timedDealProviderParams) = timedDealProvider.getData(poolId);

        params = new uint256[](4);
        params[0] = timedDealProviderParams[0];  // leftAmount
        params[1] = timedDealProviderParams[1];  // startTime
        params[2] = timedDealProviderParams[2]; // finishTime
        params[3] = timedDealProviderParams[3]; // startAmount
        params[4] = poolIdToLockDealBundle[poolId].totalAmount; // totalAmount
        params[5] = poolIdToLockDealBundle[poolId].firstSubPoolId; // firstSubPoolId
    }
}
