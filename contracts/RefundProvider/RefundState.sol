// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealProvider.sol";

abstract contract RefundState is ProviderModifiers, IProvider {
    LockDealProvider public lockProvider;

    function getData(uint256 poolId) external view override returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params){
        // underflow check
        if (poolId > 1) {
            (poolInfo, params) = IProvider(lockDealNFT.poolIdToProvider(poolId - 2)).getData(poolId - 2);
            // (poolId - 2) store data for user poolId :)
            poolInfo.poolId = poolId;
            if (lockDealNFT.exist(poolId))
                poolInfo.owner = lockDealNFT.ownerOf(poolId);
        }
    }
}