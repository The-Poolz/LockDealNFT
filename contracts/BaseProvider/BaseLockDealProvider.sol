// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is
    BaseLockDealModifiers,
    ERC20Helper,
    GovManager
{
    constructor(address provider) {
        dealProvider = DealProvider(provider);
    }

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime
    )
        public
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        poolId = dealProvider.createNewPool(owner, token, amount);
        startTimes[poolId] = startTime;
        if (!dealProvider.nftContract().approvedProviders(msg.sender)) {
            TransferInToken(token, msg.sender, amount);
            emit NewPoolCreated(
                IDealProvierEvents.BasePoolInfo(poolId, owner),
                IDealProvierEvents.Deal(token, amount),
                startTime
            );
        }
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(uint256 poolId) public returns (uint256 withdrawnAmount) {
        if (startTimes[poolId] >= block.timestamp) {
            (, withdrawnAmount) = dealProvider.poolIdToDeal(poolId);
            withdrawnAmount = dealProvider.withdraw(poolId, withdrawnAmount);
            if (!dealProvider.nftContract().approvedProviders(msg.sender)) {
                (address token, ) = dealProvider.poolIdToDeal(poolId);
                TransferToken(
                    token,
                    dealProvider.nftContract().ownerOf(poolId),
                    withdrawnAmount
                );
            }
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) public {
        dealProvider.split(poolId, splitAmount, newOwner);
    }
}
