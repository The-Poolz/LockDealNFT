// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderState.sol";

contract DealProviderModifiers is DealProviderState {
    modifier onlyOwnerOrAdmin(uint256 itemId) {
        _onlyOwnerOrAdmin(itemId);
        _;
    }

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

    modifier ValidParams(uint256[] memory params, uint256 length) {
        require(params.length == length, "Invalid params length");
        _;
    }

    function _onlyOwnerOrAdmin(uint256 itemId) private view {
        require(
            msg.sender == nftContract.ownerOf(itemId) ||
                msg.sender == nftContract.owner(),
            "Not the owner of the pool"
        );
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
}
