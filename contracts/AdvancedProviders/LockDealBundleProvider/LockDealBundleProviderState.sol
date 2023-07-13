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

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = bundlePoolIdToLastSubPoolId[poolId]; //TODO this will change to the Last Pool Id
    }

    function getTotalRemainingAmount(uint256 poolId) public view returns (uint256 totalRemainingAmount) {
        (address provider,,) = lockDealNFT.getData(poolId);
        require(provider == address(this), "not bundle poolId");

        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            (,, uint256[] memory params) = lockDealNFT.getData(i);
            totalRemainingAmount += params[0];  // leftAmount
        }
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return (tokenAValue * 1e18) / tokenBValue;
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount * 1e18 / rate;
    }
}
