// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/LockProvider/LockDealProvider.sol";
import "./FeeProvider.sol";

contract FeeLockProvider is LockDealProvider, FeeProvider {
    constructor(ILockDealNFT _lockDealNFT, IProvider _provider) LockDealProvider(_lockDealNFT, address(_provider)) {
        require(keccak256(bytes(_provider.name())) == keccak256(bytes("FeeDealProvider")), "invalid provider");
        name = "FeeLockProvider";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(FeeProvider, BasicProvider) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
