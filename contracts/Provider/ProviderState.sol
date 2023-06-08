// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";

contract ProviderState {
    LockDealNFT public lockDealNFT;

    function currentParamsTargetLenght() public view virtual returns (uint256) {
        return 1;
    }
}
