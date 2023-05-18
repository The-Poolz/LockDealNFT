// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderState.sol";

contract DealProviderModifiers is DealProviderState {
    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        _notZeroAmount(amount);
        _;
    }

    modifier validTime(uint256 startTime) {
        _validTime(startTime);
        _;
    }

    modifier invalidSplitAmount(uint256 leftAmount, uint256 splitAmount) {
        _invalidSplitAmount(leftAmount, splitAmount);
        _;
    }

    modifier onlyPoolOwner(uint256 poolId) {
        _onlyPoolOwner(poolId);
        _;
    }

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount should be greater than 0");
    }

    function _validTime(uint256 time) private view {
        require(time <= block.timestamp, "Withdrawal time not reached");
    }

    function _onlyPoolOwner(uint256 poolId) private view {
        require(msg.sender == nftContract.ownerOf(poolId));
    }

    function _invalidSplitAmount(
        uint256 leftAmount,
        uint256 splitAmount
    ) private pure {
        require(
            leftAmount >= splitAmount,
            "Split amount exceeds the available amount"
        );
    }
}
