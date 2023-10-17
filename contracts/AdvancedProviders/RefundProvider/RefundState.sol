// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../CollateralProvider/CollateralProvider.sol";
import "../../interfaces/IInnerWithdraw.sol";

abstract contract RefundState is ProviderModifiers, IInnerWithdraw, IERC165 {
    CollateralProvider public collateralProvider;
    mapping(uint256 => uint256) public poolIdToCollateralId;

    ///@return params  params [0] = tokenLeftAmount; - user(poolId + 1) data
    ///                params [1] = rateToWei
    ///                params [2] = collateralPoolId
    ///                params [3 - ...] =  time if locked or timed provider
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 userDataPoolId = poolId + 1;
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            uint256[] memory dataParams = lockDealNFT.poolIdToProvider(userDataPoolId).getParams(userDataPoolId);
            uint256 dataLength = dataParams.length;
            uint256 length = currentParamsTargetLenght() + dataLength + 1;
            params = new uint256[](length);
            // left token amount
            params[0] = dataParams[0];
            // rate to wei
            params[1] = collateralProvider.poolIdToRateToWei(collateralPoolId);
            // collateral id
            params[2] = collateralPoolId;
            uint256 k = 1;
            for (uint256 i = 3; i < length; ++i) {
                // set User data if locked or timed providers
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
