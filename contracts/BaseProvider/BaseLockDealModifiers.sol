// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseLockDealState.sol";

contract BaseLockDealModifiers is BaseLockDealState {
    modifier onlyOwnerOrAdmin(uint256 itemId) {
        require(
            msg.sender == nftContract.ownerOf(itemId) ||
                msg.sender == nftContract.owner(),
            "Not the owner of the item"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0x0), "Zero Address is not allowed");
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        require(amount > 0, "amount should be greater than 0");
        _;
    }

    modifier validTime(uint256 startTime) {
        require(startTime <= block.timestamp, "Withdrawal time not reached");
        _;
    }
}
