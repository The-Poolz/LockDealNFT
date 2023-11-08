// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";
import "../interfaces/IFundsManager.sol";
import "../interfaces/IBeforeTransfer.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

contract MockTransfer is IBeforeTransfer, DealProvider {
    bool public isBeforeTransferCalled;

    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {}

    function beforeTransfer(address, address, uint256) external sphereXGuardExternal(0x35ec591d) {
        isBeforeTransferCalled = true;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IBeforeTransfer).interfaceId || super.supportsInterface(interfaceId);
    }
}
