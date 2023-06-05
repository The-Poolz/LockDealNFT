// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../LockProvider/LockDealProvider.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables
contract TimedProviderState {
    LockDealProvider public dealProvider;
    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;
    uint256 public constant currentParamsTargetLenght = 2;

    struct TimedDeal {
        uint256 finishTime;
        uint256 startAmount;
    }
}
