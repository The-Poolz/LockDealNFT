// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IFundsManager.sol";
import "../../SimpleProviders/Provider/ProviderModifiers.sol";
import "../../util/CalcUtils.sol";
import "../../interfaces/IInnerWithdraw.sol";

abstract contract RefundState is ProviderModifiers, IInnerWithdraw, IERC165 {
    using CalcUtils for uint256;

    IFundsManager public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;

    ///@return params  params [0] = tokenLeftAmount; - user(poolId + 1) data
    ///                params [1] = user main coin amount;
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256[] memory dataParams = lockDealNFT.poolIdToProvider(poolId + 1).getParams(poolId + 1);
            params = new uint256[](2);
            uint256 tokenAmount = dataParams[0];
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            uint256 rateToWei = collateralProvider.getParams(collateralPoolId)[2];
            params[0] = tokenAmount;
            params[1] = tokenAmount.calcAmount(rateToWei);
        }
    }

    function currentParamsTargetLength() public pure override returns (uint256) {
        return 1;
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 userPoolId = poolId + 1;
            withdrawalAmount = lockDealNFT.getWithdrawableAmount(userPoolId);
        }
    }

    function getInnerIdsArray(uint256 poolId) public view override returns (uint256[] memory ids) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            ids = new uint256[](1);
            ids[0] = poolId + 1;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IInnerWithdraw).interfaceId;
    }

    function getSubProvidersPoolIds(uint256 poolId) public view virtual override returns (uint256[] memory poolIds) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            poolIds = new uint256[](2);
            poolIds[0] = poolId + 1;
            poolIds[1] = poolIdToCollateralId[poolId];
        }
    }
}
