// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../DealProvider/DealProvider.sol";

/// @title BaseLockDealState contract
/// @notice Contains storage variables, structures
contract BaseLockDealState {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;
    mapping(address => DealProvider.Provider) public providers;
}
