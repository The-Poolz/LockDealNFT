// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigrator {
    function getUserV1Amount(address user) external view returns (uint256 amount);
}
