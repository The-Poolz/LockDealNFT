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

    modifier onlyProvider() {
        _onlyProvider();
        _;
    }

    modifier validParamsLength(uint256 paramsLength, uint256 minLength) {
        _validParamsLength(paramsLength, minLength);
        _;
    }

    modifier onlyNFT() {
        _onlyNFT();
        _;
    }

    function _onlyNFT() internal view {
        require(
            msg.sender == address(lockDealNFT),
            "only NFT contract can call this function"
        );
    }

    function _validParamsLength(
        uint256 paramsLength,
        uint256 minLength
    ) private pure {
        require(paramsLength >= minLength, "invalid params length");
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

    function _onlyProvider() private view {
        require(
            lockDealNFT.approvedProviders(msg.sender),
            "invalid provider address"
        );
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
