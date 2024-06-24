// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTState.sol";

abstract contract LockDealNFTModifiers is LockDealNFTState {
    modifier onlyApprovedContract(address contractAddress) {
        _onlyApprovedContract(contractAddress);
        if (contractAddress != msg.sender) {
            _onlyApprovedContract(msg.sender);
        }
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

    modifier validPoolId(uint256 poolId) {
        _validPoolId(poolId);
        _;
    }

    function _notZeroAddress(address _address) internal pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _onlyApprovedContract(address contractAddress) internal view {
        require(approvedContracts[contractAddress], "Contract not approved");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount must be greater than 0");
    }

    function _validPoolId(uint256 poolId) internal view {
        require(_exists(poolId), "Pool does not exist");
    }
}
