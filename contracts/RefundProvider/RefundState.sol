// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealProvider.sol";
import "../CollateralProvider/CollateralProvider.sol";

abstract contract RefundState is ProviderModifiers, IProvider {
    CollateralProvider public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;
    mapping(uint256 => uint256) public poolIdToRateToWei;

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](currentParamsTargetLenght());
        params[0] = poolIdToCollateralId[poolId];
        params[1] = poolIdToRateToWei[poolId];
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 2;
    }
}