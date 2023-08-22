// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/BasicProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
abstract contract LockDealState is BasicProvider {
    ISimpleProvider public provider;
}
