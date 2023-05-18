// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseLockDealState.sol";

contract BaseLockDealModifiers is BaseLockDealState {
    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        _notZeroAmount(amount);
        _;
    }

    modifier onlyPoolOwner(uint256 poolId) {
        require(msg.sender == dealProvider.nftContract().ownerOf(poolId));
        _;
    }

    modifier validParams(uint256[] memory params, uint256 length) {
        require(params.length == length, "Invalid params length");
        _;
    }

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount should be greater than 0");
    }
}
