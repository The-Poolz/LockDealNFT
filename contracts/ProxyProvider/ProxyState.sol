// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../Provider/BasicProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
contract ProxyState {
    mapping(uint256 => ProxyData) public PoolIdtoProxyData;

    struct ProxyData{
        BasicProvider Provider;
        uint256 PoolId;
    }
}