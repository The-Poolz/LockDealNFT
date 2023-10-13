// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";
import "../../interfaces/IInnerWithdraw.sol";

abstract contract RefundState is ProviderModifiers, IInnerWithdraw, IERC165 {
    CollateralProvider public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;

    ///@return params [0] = rateToWei; - collateral data
    ///        params [1] = collateralId; - refund data
    ///        params [2] = tokenLeftAmount; - user(poolId + 1) data
    ///        params [3] = ...; - time if locked or timed provider
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 userDataPoolId = poolId + 1;
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            uint256[] memory dataParams = lockDealNFT.poolIdToProvider(userDataPoolId).getParams(userDataPoolId);
            uint256 dataLength = dataParams.length;
            uint256 length = currentParamsTargetLenght() + dataLength + 1;
            params = new uint256[](length);
            // set Collateral data
            params[0] = collateralProvider.poolIdToRateToWei(collateralPoolId);
            // set RefundProvider data
            params[1] = collateralPoolId;
            uint256 k = 0;
            for (uint256 i = 2; i < length; ++i) {
                // set User data
                params[i] = dataParams[k++];
            }
        }
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
