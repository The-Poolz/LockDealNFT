// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../../SimpleProviders/Provider/ProviderModifiers.sol";
import "../../ERC165/Refundble.sol";

/// @title BundleProviderState contract
/// @notice Contains storage variables
abstract contract BundleProviderState is IProvider, ProviderModifiers, ERC165 {
    mapping(uint256 => uint256) public bundlePoolIdToLastSubPoolId;

    function _calcTotalAmount(uint256[][] calldata params) internal pure returns (uint256 totalAmount) {
        uint length = params.length;
        for (uint256 i = 0; i < length; ++i) {
            totalAmount += params[i][0];
        }
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
            for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
                uint256 subPoolwithdrawalAmount = lockDealNFT.getWithdrawableAmount(i);
                withdrawalAmount += subPoolwithdrawalAmount;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == Refundble._INTERFACE_ID_REFUNDABLE || super.supportsInterface(interfaceId);
    }
}
