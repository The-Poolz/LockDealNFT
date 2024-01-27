// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/LockProvider/LockDealProvider.sol";

contract FeeLockProvider is LockDealProvider {
    constructor(ILockDealNFT lockDealNFT, FeeDealProvider provider) LockDealProvider(lockDealNFT, address provider) {
        require(provider.name() == "FeeDealProvider", "invalid provider");
    }

    name() external override pure returns (string memory) {
        return "FeeLockProvider";
    }
}