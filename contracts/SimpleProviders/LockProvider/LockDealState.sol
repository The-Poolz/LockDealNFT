// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../LockDealNFT/LockDealNFT.sol";
import "../DealProvider/DealProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
abstract contract LockDealState is BasicProvider {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;
}