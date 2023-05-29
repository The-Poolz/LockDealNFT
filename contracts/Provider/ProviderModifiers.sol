// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderState.sol";

contract ProviderModifiers is ProviderState {
    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        _notZeroAmount(amount);
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

    function _onlyProvider() private view {
        require(
            lockDealNFT.approvedProviders(msg.sender),
            "invalid provider address"
        );
    }
}
