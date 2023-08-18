// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract DealProviderState {
    mapping(uint256 => uint256) public poolIdToAmount;
}
