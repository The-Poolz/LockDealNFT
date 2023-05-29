// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IProviderEvents.sol";

contract ProviderState is IProviderEvents {
    LockDealNFT public lockDealNFT;
}
