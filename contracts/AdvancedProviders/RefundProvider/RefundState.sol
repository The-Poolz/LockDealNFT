// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";
import "../../interfaces/IInnerWithdraw.sol";

abstract contract RefundState is ProviderModifiers, IInnerWithdraw, IERC165 {
    CollateralProvider public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;

    ///@return params - UserData, CollateralData, RefundProviderData
    ///        params[0] - LeftTokenAmount
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 userDataPoolId = poolId + 1;
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            uint256 dataParamsTargetLength = lockDealNFT.poolIdToProvider(userDataPoolId).currentParamsTargetLenght();
            uint256 collateralLength = collateralProvider.currentParamsTargetLenght();
            uint256 length = currentParamsTargetLenght() + dataParamsTargetLength + collateralLength;
            params = new uint256[](length);
            // add UserData
            params = _setDataParams(userDataPoolId, params); // first index LeftTokenAmount
            // add CollateralData
            params = _setCollateralParams(collateralPoolId, dataParamsTargetLength, params);
            // add RefundProviderData
            params[length - 1] = collateralPoolId; // last index collateralPoolId
        }
    }

    function _setDataParams(uint256 poolId, uint256[] memory params) internal view returns (uint256[] memory) {
        uint256[] memory dataParams = lockDealNFT.poolIdToProvider(poolId).getParams(poolId);
        uint256 dataLength = dataParams.length;
        for (uint256 i = 0; i < dataLength; ++i) {
            params[i] = dataParams[i];
        }
        return params;
    }

    function _setCollateralParams(
        uint256 poolId,
        uint256 fromIndex,
        uint256[] memory params
    ) internal view returns (uint256[] memory) {
        uint256[] memory collateralParams = collateralProvider.getParams(poolId);
        params[fromIndex] = collateralParams[0];
        params[fromIndex + 1] = collateralParams[1];
        params[fromIndex + 2] = collateralParams[2];
        return params;
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
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
}
