// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealProvider.sol";

abstract contract RefundState is ProviderModifiers, IProvider {
    LockDealProvider public lockProvider;
    mapping(uint256 => address) public poolIdToProjectOwner;

    function getParams(uint256 poolId) external view override returns (uint256[] memory params){
        //TODO implement
    }
}