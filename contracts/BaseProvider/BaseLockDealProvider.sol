// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/Array.sol";
import "../interface/ICustomLockedDeal.sol";
import "./IBaseLockEvents.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is
    ICustomLockedDeal,
    IBaseLockEvents,
    BaseLockDealModifiers,
    ERC20Helper
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function createNewPool(
        address recipient,
        address tokenAddress,
        uint256 startTime,
        uint256 amount
    ) external virtual returns (uint256){
        TransferInToken(tokenAddress, tx.origin, amount);
        return _createNewPool(recipient, tokenAddress, amount, startTime);
    }

    function createMassPool(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory startTimes,
        uint256[] memory amounts
    ) external virtual {
        require(amounts.length == startTimes.length 
        && recipients.length == startTimes.length, "Invalid input");
        TransferInToken(tokenAddress, tx.origin, Array.getArraySum(amounts));
        for (uint256 i = 0; i < startTimes.length; i++) {
            _createNewPool(recipients[i], tokenAddress, amounts[i], startTimes[i]);
        }
    }

    function createPoolsWrtTime(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory startTimes,
        uint256[] memory amounts
    ) external virtual {
        require(amounts.length == recipients.length, "Invalid input");
        TransferInToken(
            tokenAddress,
            tx.origin,
            Array.getArraySum(amounts) * startTimes.length
        );
        for (uint256 i = 0; i < startTimes.length; i++) {
            for(uint256 j = 0; j < amounts.length; j++) {
                _createNewPool(recipients[i], tokenAddress, amounts[j], startTimes[i]);
            }
        }
    }
    
    function withdraw(
        uint256 itemId
    )
        external
        virtual
        override
        onlyOwnerOrAdmin(itemId)
        notZeroAmount(itemIdToDeal[itemId].amount)
        validTime(itemIdToDeal[itemId].startTime)
        returns (uint256 withdrawnAmount)
    {
        Deal storage deal = itemIdToDeal[itemId];
        if(deal.startTime > block.timestamp) return 0;
        withdrawnAmount = deal.amount;
        deal.amount = 0;
        TransferToken(
            deal.tokenAddress,
            nftContract.ownerOf(itemId),
            withdrawnAmount
        );
        emit TokenWithdrawn(
            itemId,
            deal.tokenAddress,
            withdrawnAmount,
            nftContract.ownerOf(itemId)
        );
    }

    function split(
        address to,
        uint256 itemId,
        uint256 splitAmount
    )
        external
        virtual
        override
        notZeroAmount(splitAmount)
        onlyOwnerOrAdmin(itemId)
    {
        Deal storage deal = itemIdToDeal[itemId];
        require(
            deal.amount >= splitAmount,
            "Split amount exceeds the available amount"
        );
        deal.amount -= splitAmount;
        _createNewPool(to, deal.tokenAddress, splitAmount, deal.startTime);
    }

    function _createNewPool(
        address to,
        address tokenAddress,
        uint256 startTime,
        uint256 amount
    ) internal virtual returns (uint256 newItemId) {
        newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(tokenAddress, amount, startTime);
        nftContract.mint(to);
        emit NewPoolCreated(newItemId, tokenAddress, startTime, amount, to);
    }
}
