// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedDealProvider/TimedDealProvider.sol";
import "./FeeProvider.sol";

contract FeeTimedProvider is TimedDealProvider, FeeProvider {
    constructor(ILockDealNFT lockDealNFT, IProvider _provider) TimedDealProvider(lockDealNFT, address(_provider)) {
        require(keccak256(bytes(_provider.name())) == keccak256(bytes("FeeLockProvider")), "invalid provider");
        name = "FeeTimedProvider";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(FeeProvider, BasicProvider) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
