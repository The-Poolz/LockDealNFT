// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";

abstract contract RefundState is ProviderModifiers {
    CollateralProvider public collateralProvider;

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](currentParamsTargetLenght() + 1);
        params[0] = lockDealNFT.poolIdToProvider(poolId + 1).getParams(poolId + 1)[0];
        params[1] = poolData[poolId][0];
        params[2] = poolData[poolId][1];
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 2;
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 userPoolId = poolId + 1;
            withdrawalAmount = lockDealNFT.getWithdrawableAmount(userPoolId);
        }
    }
}
