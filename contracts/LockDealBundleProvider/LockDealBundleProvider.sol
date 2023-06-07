// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderState.sol";
import "../Provider/ProviderModifiers.sol";
import "../ProviderInterface/IProvider.sol";

contract LockDealBundleProvider is
    ProviderModifiers,
    LockDealBundleProviderState,
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

    ///@param providerParams[0] = leftAmount
    ///@param providerParams[1] = startTime
    ///@param providerParams[2] = finishTime
    ///@param providerParams[3] = startAmount
    function createNewPool(
        address owner,
        address token,
        address[] calldata providers,
        uint256[][] calldata providerParams
    ) external returns (uint256 poolId) {
        // amount for LockDealProvider = `totalAmount` - `startAmount`
        // amount for TimedDealProvider = `startAmount`

        // mint the NFT owned by the BunderDealProvider on LockDealProvider for `totalAmount` - `startAmount` token amount
        // mint the NFT owned by the BunderDealProvider on TimedDealProvider for `startAmount` token amount
        // mint the NFT owned by the owner on LockDealBundleProvider for `totalAmount` token transfer amount

        // To optimize the token transfer (for 1 token transfer)
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on LockDealProvider
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on TimedDealProvider
        // mint the NFT owned by the owner with `totalAmount` token transfer amount on LockDealBundleProvider

        require(providers.length == providerParams.length, "providers and params length mismatch");

        LockDealProvider lockDealProvider = timedDealProvider.dealProvider();
        DealProvider dealProvider = lockDealProvider.dealProvider();

        uint256 firstSubPoolId;
        uint256 totalStartAmount;
        for (uint256 i; i < providers.length; ++i) {
            address provider = providers[i];
            uint256[] memory params = providerParams[i];

            // check if the provider address is valid
            require(
                provider == address(dealProvider) ||
                provider == address(lockDealProvider) ||
                provider == address(timedDealProvider),
                "invalid provider address"
            );

            // create the pool and store the first sub poolId
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            uint256 subPoolId = lockDealNFT.mint(address(this), token, msg.sender, 0);
            if (firstSubPoolId == 0) firstSubPoolId = subPoolId;
            IProvider(provider).registerPool(subPoolId, owner, token, params);

            // calculate the total start amount
            totalStartAmount += params[0];

            // in case `TimedDealProvider`, add the missing checks from `createNewPool` function and ensure that `totalAmount` is correct
            if (provider == address(timedDealProvider)) {
                require(
                    params[2] >= params[1],
                    "Finish time should be greater than start time"
                );
                require(
                    params[0] == params[3],
                    "Start amount should be equal to left amount"
                );
            }
        }

        // create a new pool owned by teh owner with `totalStartAmount` token trasnfer amount
        poolId = lockDealNFT.mint(owner, token, msg.sender, totalStartAmount);
        _registerPool(poolId, totalStartAmount, firstSubPoolId);
        isLockDealBundlePoolId[poolId] = true;
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
    //     uint256 firstSubPoolId = poolIdToLockDealBundle[poolId].firstSubPoolId;
    //     for (uint256 i = firstSubPoolId; i < poolId; ++i) {
    //         (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    //     }
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
    //     (withdrawnAmount, isFinal) = timedDealProvider.withdraw(poolId, amount);
    }

    // function _withdraw(
    //     uint256 poolId,
    //     uint256 amount
    // ) internal returns (uint256 withdrawnAmount, bool isFinal) {
    //     (withdrawnAmount, isFinal) = timedDealProvider.withdraw(poolId, amount);
    // }

    // function getWithdrawableAmount(
    //     uint256 poolId
    // ) public view returns (uint256) {
    //     (, uint256[] memory poolParams) = getData(poolId);
    //     uint256 leftAmount = poolParams[0];
    //     uint256 startTime = poolParams[1];
    //     uint256 finishTime = poolParams[2];
    //     uint256 startAmount = poolParams[3];

    //     if (block.timestamp < startTime) return 0;
    //     if (finishTime < block.timestamp) return leftAmount;

    //     uint256 totalPoolDuration = finishTime - startTime;
    //     uint256 timePassed = block.timestamp - startTime;
    //     uint256 debitableAmount = (startAmount * timePassed) / totalPoolDuration;
    //     return debitableAmount - (startAmount - leftAmount);
    // }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public onlyProvider {
    //     timedDealProvider.split(oldPoolId, newPoolId, splitAmount);
    //     uint256 newPoolStartAmount = poolIdToTimedDeal[oldPoolId].startAmount -
    //         splitAmount;
    //     poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
    //     poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
    //     poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId]
    //         .finishTime;
    }

    // function getParametersTargetLenght() public view returns (uint256) {
    //     return
    //         currentParamsTargetLenght +
    //         timedDealProvider.getParametersTargetLenght();
    // }

    ///@param params[0] = totalStartAmount
    ///@param params[1] = firstSubPoolId
    function registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) public override onlyProvider {
    //     _registerPool(poolId, owner, token, params, firstSubPoolId);
    }

    function _registerPool(
        uint256 poolId,
        uint256 totalStartAmount,
        uint256 firstSubPoolId
    ) internal {
        poolIdToLockDealBundle[poolId].totalStartAmount = totalStartAmount;
        poolIdToLockDealBundle[poolId].firstSubPoolId = firstSubPoolId;
    }

    function getData(uint256 poolId) public override view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        require(isLockDealBundlePoolId[poolId], "invalid poolId");

        address owner = lockDealNFT.ownerOf(poolId);
        poolInfo = IDealProvierEvents.BasePoolInfo(poolId, owner, address(0));
        params = new uint256[](2);
        params[0] = poolIdToLockDealBundle[poolId].totalStartAmount; // totalStartAmount
        params[1] = poolIdToLockDealBundle[poolId].firstSubPoolId; // firstSubPoolId
    }
}
