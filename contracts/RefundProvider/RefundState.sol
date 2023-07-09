// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealProvider.sol";

abstract contract RefundState is ProviderModifiers, IProvider {
    LockDealProvider public lockProvider;
    mapping(uint256 => address) public poolIdToProjectOwner;

    function getData(uint256 poolId) external view override returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params){
        if (lockDealNFT.exist(poolId - 2)) {
            (poolInfo, params) = IProvider(lockDealNFT.poolIdToProvider(poolId - 2)).getData(poolId - 2);
            poolInfo.poolId = poolId;
            if (lockDealNFT.exist(poolId))
                poolInfo.owner = lockDealNFT.ownerOf(poolId);
        }
    }
}