// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IBaseLockDealEvents.sol";

/// @title BaseLockDealState contract
/// @notice Contains storage variables, structures
contract BaseLockDealState is IBaseLockDealEvents {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;

    function getParams(
        uint256 leftAmount,
        uint256 startTime
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = leftAmount;
        params[1] = startTime;
    }
}
