// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
contract ProxyState {
    mapping(uint256 => ProxyData) public PoolIdtoProxyData;

    struct ProxyData{
        address Provider;
        uint256 PoolId;
    }
}