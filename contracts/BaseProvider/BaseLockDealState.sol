// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IBaseLockDealEvents.sol";

/// @title BaseLockDealState contract
/// @notice Contains storage variables, structures
contract BaseLockDealState is IBaseLockDealEvents {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;
}
