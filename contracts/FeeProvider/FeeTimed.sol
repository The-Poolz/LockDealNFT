// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedProvider/TimedDealProvider.sol";

contract FeeTimedProvider is TimedDealProvider {
    constructor(ILockDealNFT lockDealNFT, FeeLockProvider provider) TimedDealProvider(lockDealNFT, address provider) {
        require(provider.name() == "FeeLockProvider", "invalid provider");
    }

    name() external override pure returns (string memory) {
        return "FeeTimedProvider";
    }
}