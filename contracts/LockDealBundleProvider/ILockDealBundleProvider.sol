// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockDealBundleProvider {
    function split(uint256 bundlePoolId, address token, uint256[] memory splitAmounts, address newOwner) external;
}