// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";

/// @title LockDealBundleProviderState contract
/// @notice Contains storage variables
contract LockDealBundleProviderState {
    mapping(uint256 => uint256) public bundlePoolIdToFirstPoolId;
}
