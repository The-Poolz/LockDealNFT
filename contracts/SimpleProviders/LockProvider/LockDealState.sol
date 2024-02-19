// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ISimpleProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
abstract contract LockDealState {
    ISimpleProvider public provider;
    mapping(uint256 => uint256) public poolIdToTime;
}
