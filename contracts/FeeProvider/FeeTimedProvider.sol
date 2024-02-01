// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedDealProvider/TimedDealProvider.sol";

contract FeeTimedProvider is TimedDealProvider {
    constructor(ILockDealNFT lockDealNFT, IProvider _provider) TimedDealProvider(lockDealNFT, address(_provider)) {
        require(keccak256(bytes(_provider.name())) == keccak256(bytes("FeeLockProvider")), "invalid provider");
        name = "FeeTimedProvider";
    }
}
