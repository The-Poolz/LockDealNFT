// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProviderSingleIdRegistrar {
    function registerPool(uint256 poolId, uint256[] calldata params) external;
}