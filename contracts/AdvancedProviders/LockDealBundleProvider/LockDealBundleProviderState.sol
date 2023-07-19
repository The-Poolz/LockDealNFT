// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../LockDealNFT/LockDealNFT.sol";
import "../../SimpleProviders/Provider/ProviderModifiers.sol";

/// @title LockDealBundleProviderState contract
/// @notice Contains storage variables
abstract contract LockDealBundleProviderState is IProvider, ProviderModifiers {
    mapping(uint256 => uint256) public bundlePoolIdToLastSubPoolId;

    function _calcTotalAmount(uint256[][] calldata params) internal pure returns (uint256 totalAmount) {
        uint length = params.length;
        for (uint256 i = 0; i < length; ++i) {
            totalAmount += params[i][0];
        }
    }
}
