// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SimpleProviders/Provider/ProviderModifiers.sol";

/// @title BundleProviderState contract
/// @notice Contains storage variables
abstract contract BundleProviderState is IProvider, ProviderModifiers {
    mapping(uint256 => uint256) public bundlePoolIdToLastSubPoolId;

    function _calcTotalAmount(uint256[][] calldata params) internal pure returns (uint256 totalAmount) {
        uint length = params.length;
        for (uint256 i = 0; i < length; ++i) {
            totalAmount += params[i][0];
        }
    }

    function getWithdrawableAmount(
        uint256 poolId
    ) external view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
            for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
                (uint256 subPoolwithdrawalAmount) = lockDealNFT.getWithdrawableAmount(i);
                withdrawalAmount += subPoolwithdrawalAmount;
            }
        }
    }
}
