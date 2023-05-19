// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseLockDealState.sol";

contract BaseLockDealModifiers is BaseLockDealState {
    modifier validParams(uint256[] memory params, uint256 length) {
        require(params.length == length, "Invalid params length");
        _;
    }

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }
}
