// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IProvider.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is BaseLockDealModifiers, ERC20Helper, IProvider {
    constructor(address provider) {
        dealProvider = DealProvider(provider);
    }

    /// params[0] = amount
    /// params[1] = startTime
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = dealProvider.createNewPool(owner, token, params);
        startTimes[poolId] = params[1];
        if (!dealProvider.nftContract().approvedProviders(msg.sender)) {
            TransferInToken(token, msg.sender, params[0]);
        }
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        if (startTimes[poolId] >= block.timestamp) {
            withdrawnAmount = dealProvider.withdraw(poolId);
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) public override {
        dealProvider.split(poolId, splitAmount, newOwner);
    }
}
