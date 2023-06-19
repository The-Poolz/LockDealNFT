// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProvider.sol";
import "../LockProvider/LockDealProvider.sol";
import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/GovManager.sol";

contract RefundState is GovManager {
    LockDealProvider public lockProvider;
}