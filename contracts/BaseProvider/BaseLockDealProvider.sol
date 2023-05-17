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
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        params = new uint256[](2);
        params[0] = amount;
        poolId = dealProvider.createNewPool(owner, token, amount);
        startTimes[poolId] = startTime;
        TransferInToken(token, msg.sender, amount);
        // emit NewPoolCreated(
        //     createBasePoolInfo(poolId, owner, token),
        //     GetParams(amount, startTime)
        // );
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) external returns (uint256 withdrawnAmount) {
        if (
            startTimes[poolId] >= block.timestamp &&
            (msg.sender == dealProvider.nftContract().ownerOf(poolId) ||
                msg.sender == dealProvider.nftContract().owner() ||
                providers[msg.sender].status)
        ) {
            (, withdrawnAmount) = dealProvider.poolIdToDeal(poolId);
            withdrawnAmount = dealProvider.withdraw(poolId, withdrawnAmount);
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
        // Deal storage deal = poolIdToDeal[poolId];
        // require(
        //     deal.startAmount >= splitAmount,
        //     "Split amount exceeds the available amount"
        // );
        // deal.startAmount -= splitAmount;
        // uint256 newPoolId = _createNewPool(
        //     newOwner,
        //     deal.token,
        //     GetParams(splitAmount, deal.startTime)
        // );
        // emit PoolSplit(
        //     createBasePoolInfo(poolId, nftContract.ownerOf(poolId), deal.token),
        //     createBasePoolInfo(newPoolId, newOwner, deal.token),
        //     splitAmount
        // );
    }
}
