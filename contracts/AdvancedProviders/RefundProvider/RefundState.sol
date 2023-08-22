// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";

abstract contract RefundState is ProviderModifiers {
    CollateralProvider public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;
    mapping(uint256 => uint256) public poolIdToRateToWei;

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](currentParamsTargetLenght() + 1);
        params[0] = lockDealNFT.poolIdToProvider(poolId + 1).getParams(poolId + 1)[0];
        params[1] = poolIdToCollateralId[poolId];
        params[2] = poolIdToRateToWei[poolId];
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
