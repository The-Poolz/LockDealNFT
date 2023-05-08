// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/ICustomItemInterface.sol";
import "../LockDealNFT/LockDealNFT.sol";

abstract contract BaseLockDealProvider is ICustomItemInterface {
    struct Deal {
        address tokenAddress;
        uint256 amount;
        uint256 startTime;
    }

    LockDealNFT private nftContract;
    mapping(uint256 => Deal) public itemIdToDeal;

    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function mint(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime
    ) external virtual override {
        //uint256 newItemId = nftContract.totalSupply();
        nftContract.mint(to);
        uint256 newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(tokenAddress, amount, startTime);
        //_mint(to, tokenAddress, amount, startTime);
    }

    function withdraw(uint256 itemId) external virtual override {
        Deal storage deal = itemIdToDeal[itemId];

        require(
            msg.sender == nftContract.ownerOf(itemId),
            "Not the owner of the item"
        );
        require(
            deal.startTime <= block.timestamp,
            "Withdrawal time not reached"
        );
        require(deal.amount > 0, "No amount left to withdraw");

        // Implement the logic for transferring tokens from this contract to msg.sender
        // For example, if it's an ERC20 token, use the ERC20 contract's transfer function
    }

    function split(
        address to,
        uint256 itemId,
        uint256 splitAmount
    ) external virtual override {
        require(splitAmount > 0, "Split amount should be greater than 0");

        Deal storage deal = itemIdToDeal[itemId];

        require(
            msg.sender == nftContract.ownerOf(itemId),
            "Not the owner of the item"
        );
        require(
            deal.amount >= splitAmount,
            "Split amount exceeds the available amount"
        );

        deal.amount -= splitAmount;

        _mint(to, deal.tokenAddress, splitAmount, deal.startTime);
    }

    function _mint(
        address to,
        address tokenAddress,
        uint256 amount,
        uint256 startTime
    ) internal {
        nftContract.mint(to);
        uint256 newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(tokenAddress, amount, startTime);
    }

    function isRefundable(uint256 itemId) public view returns (bool) {
        return false;
    }
}
