// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderState.sol";

contract LockDealBundleProviderModifiers is LockDealBundleProviderState {
    modifier onlyBundlePoolId(uint256 poolId) {
        _invalidBundlePoolId(poolId);
        _;
    }

    function _invalidBundlePoolId(
        uint256 poolId
    ) internal view {
        require(
            isLockDealBundlePoolId[poolId],
            "Pool is not a bundle pool"
        );
    }
}
