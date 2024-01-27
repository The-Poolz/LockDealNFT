// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/LockProvider/LockDealProvider.sol";
import "../interfaces/ILockDealNFT.sol"; 

contract FeeLockProvider is LockDealProvider {
    constructor(ILockDealNFT _lockDealNFT, IProvider _provider) LockDealProvider(_lockDealNFT, _provider) {
        require(_provider.name() == "FeeDealProvider", "invalid provider");
    }

    function name() external override pure returns (string memory) {
        return "FeeLockProvider";
    }
}
