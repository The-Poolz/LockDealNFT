// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";
import "../interfaces/IBeforeTransfer.sol";

contract MockTransfer is IBeforeTransfer, DealProvider {
    bool public isBeforeTransferCalled;

    constructor(ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {}

    function beforeTransfer(address, address, uint256) external {
        isBeforeTransferCalled = true;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IBeforeTransfer).interfaceId || super.supportsInterface(interfaceId);
    }
}
