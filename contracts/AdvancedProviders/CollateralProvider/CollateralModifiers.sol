// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollateralState.sol";

abstract contract CollateralModifiers is CollateralState {
    modifier validProviderId(uint256 poolId) {
        _validProviderId(poolId);
        _;
    }

    function _validProviderId(uint256 poolId) internal view {
        require(lockDealNFT.poolIdToProvider(poolId) == this, "Invalid provider");
    }
}
