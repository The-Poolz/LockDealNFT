// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";

contract CollateralModifiers is LockDealState, ProviderModifiers {
    modifier validProviderId(uint256 poolId) {
        require(
            address(lockDealNFT.providerOf(poolId)) == address(this),
            "Invalid provider"
        );
        _;
    }
}
