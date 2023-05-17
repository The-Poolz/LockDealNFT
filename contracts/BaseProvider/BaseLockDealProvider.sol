// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./BaseLockDealModifiers.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";

contract BaseLockDealProvider is BaseLockDealModifiers, ERC20Helper {
    constructor(address provider) {
        dealProvider = DealProvider(provider);
    }

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        poolId = dealProvider.createNewPool(owner, token, amount);
        startTimes[poolId] = startTime;
        //TransferInToken(token, msg.sender, amount);
    }

    function withdraw(
        uint256 poolId
    ) external returns (uint256 withdrawnAmount) {
        if (
            startTimes[poolId] >= block.timestamp &&
            (msg.sender == dealProvider.nftContract().ownerOf(poolId) ||
                msg.sender == dealProvider.nftContract().owner())
        ) {
            (, withdrawnAmount) = dealProvider.poolIdToDeal(poolId);
            dealProvider.withdraw(poolId, withdrawnAmount);
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    )
        external
        notZeroAmount(splitAmount)
        notZeroAddress(newOwner)
        onlyPoolOwner(poolId)
    {
        dealProvider.split(poolId, splitAmount, newOwner);
    }
}
