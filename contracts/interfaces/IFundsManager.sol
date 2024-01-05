// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISimpleProvider.sol";

interface IFundsManager is IProvider {
    function handleWithdraw(uint256 poolId, uint256 tokenAmount) external;
    function handleRefund(uint256 poolId, address user, uint256 tokenAmount) external;
}
