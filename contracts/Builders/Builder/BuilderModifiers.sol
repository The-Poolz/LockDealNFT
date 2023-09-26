// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./BuilderState.sol";

contract BuilderModifiers is BuilderState {
    modifier notZeroAddress(address _address) {
        _notZeroAddress(_address);
        _;
    }

    modifier notZeroAmount(uint256 amount) {
        _notZeroAmount(amount);
        _;
    }

    modifier validUserData(UserPool memory userData) {
        _notZeroAddress(userData.user);
        _notZeroAmount(userData.amount);
        _;
    }

    modifier validParamsLength(uint256 paramsLength, uint256 minLength) {
        _validParamsLength(paramsLength, minLength);
        _;
    }

    function _notZeroAmount(uint256 amount) internal pure {
        require(amount > 0, "amount must be greater than 0");
    }

    function _notZeroAddress(address _address) internal pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _validParamsLength(uint256 paramsLength, uint256 minLength) internal pure {
        require(paramsLength >= minLength, "invalid params length");
    }
}
