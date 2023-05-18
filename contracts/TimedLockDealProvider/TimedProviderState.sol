// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./ITimedLockDealEvents.sol";
import "../BaseProvider/BaseLockDealProvider.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract TimedProviderState is ITimedLockDealEvents {
    BaseLockDealProvider public dealProvider;
    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;
}
