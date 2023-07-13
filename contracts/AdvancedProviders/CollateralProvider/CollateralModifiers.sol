// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollateralState.sol";

abstract contract CollateralModifiers is CollateralState {
    modifier validProviderId(uint256 poolId) {
        require(
            lockDealNFT.poolIdToProvider(poolId) == this,
            "Invalid provider"
        );
        _;
    }
}
