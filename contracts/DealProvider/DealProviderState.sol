// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract DealProviderState {
    mapping(uint256 => Deal) public itemIdToDeal;
    struct Deal {
        address token; //Part of the Base info
        uint256 leftAmount; //the first param
    }
    function getArray(uint256 leftAmount) public pure returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = leftAmount;
    }
}
