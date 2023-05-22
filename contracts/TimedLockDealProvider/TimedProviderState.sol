// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./ITimedLockDealEvents.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract TimedProviderState is ITimedLockDealEvents {
    BaseLockDealProvider public dealProvider;
    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;
    uint256 public constant currentParamsTargetLenght = 2;

    function getParams(
        uint256 leftAmount,
        uint256 startTime,
        uint256 finishTime,
        uint256 withdrawnAmount
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](4);
        params[0] = leftAmount;
        params[1] = startTime;
        params[2] = finishTime;
        params[3] = withdrawnAmount;
    }
}
