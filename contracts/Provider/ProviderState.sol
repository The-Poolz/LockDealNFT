// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IProvierEvents.sol";

contract ProviderState is IProvierEvents {
    LockDealNFT public lockDealNFT;
}
