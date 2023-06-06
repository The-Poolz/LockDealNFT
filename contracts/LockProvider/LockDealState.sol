// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../DealProvider/DealProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
contract LockDealState {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;
    uint256 public constant currentParamsTargetLenght = 1;

    function getParametersTargetLenght() public view returns (uint256) {
        return currentParamsTargetLenght + dealProvider.currentParamsTargetLenght();
    }
}