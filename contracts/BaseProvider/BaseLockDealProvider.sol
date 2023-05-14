// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/IInitiator.sol";
import "../DealProvider/DealProvider.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";
import "./IBaseLockEvents.sol";

contract BaseLockDealProvider is DealProvider, IBaseLockEvents, IInitiator {
    constructor(address nftContract) DealProvider(nftContract) {}

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime
    ) external returns (uint256 poolId) {
        _initiateNewPool(token, amount, startTime, owner);
        TransferInToken(token, msg.sender, amount);
    }

    function _initiateNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime
    )
        internal
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        uint256 poolId = _createNewPool(token, amount, startTime, owner);
        emit NewPoolCreated(poolId, token, startTime, amount, owner);
    }

    function initiate(
        address owner,
        address token,
        uint[] memory params
    ) external returns (uint256 poolId) {
        require(params.length == 2, "Incorrect number of parameters");
        //require approved msgsender (the bandle, or other contract that will asume the tokens are locked)
        uint256 poolId = _initiateNewPool(owner,token, params[0], params[1] );
    }

    function withdraw(
        uint256 itemId
    )
        external
        virtual
        override
        onlyOwnerOrAdmin(itemId)
        notZeroAmount(itemIdToDeal[itemId].startAmount)
        validTime(itemIdToDeal[itemId].startTime)
        returns (uint256 withdrawnAmount)
    {
        withdrawnAmount = itemIdToDeal[itemId].startAmount;
        itemIdToDeal[itemId].startAmount = 0;
        _withdraw(itemId, withdrawnAmount);
        emit TokenWithdrawn(
            itemId,
            itemIdToDeal[itemId].token,
            withdrawnAmount,
            nftContract.ownerOf(itemId)
        );
    }

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    )
        external
        virtual
        override
        notZeroAmount(splitAmount)
        notZeroAddress(newOwner)
        onlyOwnerOrAdmin(itemId)
    {
        Deal storage deal = itemIdToDeal[itemId];
        require(
            deal.startAmount >= splitAmount,
            "Split amount exceeds the available amount"
        );
        deal.startAmount -= splitAmount;
        uint256 newPoolId = _createNewPool(
            deal.token,
            splitAmount,
            deal.startTime,
            newOwner
        );
        emit PoolSplit(
            itemId,
            newPoolId,
            deal.startAmount,
            splitAmount,
            nftContract.ownerOf(itemId),
            newOwner
        );
    }
}
