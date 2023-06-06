// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../TimedDealProvider/TimedDealProvider.sol";

/// @title LockDealBundleProviderState contract
/// @notice Contains storage variables
contract LockDealBundleProviderState {
    TimedDealProvider public timedDealProvider;
    mapping(uint256 => LockDealBundle) public poolIdToLockDealBundle;
    uint256 public constant currentParamsTargetLenght = 1;

    struct LockDealBundle {
        uint256 totalAmount;
        uint256 firstSubPoolId;
    }
}
