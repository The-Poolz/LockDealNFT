// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderState.sol";

contract DealProviderModifiers is DealProviderState {
    modifier invalidSplitAmount(uint256 leftAmount, uint256 splitAmount) {
        _invalidSplitAmount(leftAmount, splitAmount);
        _;
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
