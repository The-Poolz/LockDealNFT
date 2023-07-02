// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/BasicProvider.sol";

abstract contract IDeposit is BasicProvider{
    function deposit(uint256 poolId, uint256 amount) external;
}