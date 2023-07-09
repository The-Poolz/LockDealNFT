// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";

abstract contract RefundState is ProviderModifiers, IProvider {
    CollateralProvider public collateralProvider;

    function getParams(uint256 poolId) external view override returns (uint256[] memory params){
        uint256 dataPoolId = poolId + 1;
        if(lockDealNFT.exist(dataPoolId)) {
            params = lockDealNFT.providerOf(dataPoolId).getParams(dataPoolId);
        }
    }
}