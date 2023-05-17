// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../BaseProvider/BaseLockDealState.sol";
import "../Provider/Provider.sol";

contract BaseLockDealProvider is Provider, BaseLockDealState {
    constructor(address _nftContract, address _provider) 
    Provider(_nftContract)
    BaseLockDealState(_provider)
    {}
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
       poolId = mint(owner);
       
    }

    function withdraw(
        uint256 itemId
    )
        external
        virtual
        override
        onlyOwnerOrAdmin(itemId)
        returns (uint256 withdrawnAmount)
    {
        //withdrawnAmount = itemIdToDeal[itemId].startAmount;//need to be from its own struct
        //itemIdToDeal[itemId].startAmount = 0;//need to be from its own struct
        //_withdraw(itemId, withdrawnAmount);
        //emit TokenWithdrawn(
        //    createBasePoolInfo(
        //        itemId,
        //        nftContract.ownerOf(itemId),
        //        itemIdToDeal[itemId].token
        //    ),
        //    withdrawnAmount,
        //    itemIdToDeal[itemId].startAmount
        //);
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
       // Deal storage deal = itemIdToDeal[itemId]; //need to be from its own struct
      //  require(
       //     deal.startAmount >= splitAmount,
       //     "Split amount exceeds the available amount"
       // );
       // deal.startAmount -= splitAmount;
       // uint256 newPoolId = _createNewPool(
        //    newOwner,
        //    deal.token,
        //    GetParams(splitAmount, deal.startTime) 
       // );
      //  emit PoolSplit(
      //      createBasePoolInfo(itemId, nftContract.ownerOf(itemId), deal.token),
       //     createBasePoolInfo(newPoolId, newOwner, deal.token),
        //    splitAmount
       // );
    }
}
