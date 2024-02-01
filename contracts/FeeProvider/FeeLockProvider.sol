// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/LockProvider/LockDealProvider.sol";

contract FeeLockProvider is LockDealProvider {
    constructor(ILockDealNFT _lockDealNFT, IProvider _provider) LockDealProvider(_lockDealNFT, address(_provider)) {
        require(keccak256(bytes(_provider.name())) == keccak256(bytes("FeeDealProvider")), "invalid provider");
        name = "FeeLockProvider";
    }
}
