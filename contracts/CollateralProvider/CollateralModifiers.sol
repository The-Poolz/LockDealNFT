// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollateralState.sol";

contract CollateralModifiers is CollateralState {
    modifier validProviderId(uint256 poolId) {
        require(
            address(lockDealNFT.providerOf(poolId)) == address(this),
            "Invalid provider"
        );
        _;
    }
}
