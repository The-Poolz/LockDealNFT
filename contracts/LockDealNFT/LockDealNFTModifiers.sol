// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTState.sol";

abstract contract LockDealNFTModifiers is LockDealNFTState {
    modifier onlyApprovedProvider(address provider) {
        _onlyApprovedProvider(provider);
        if (address(provider) != msg.sender) {
            _onlyApprovedProvider(msg.sender);
        }
        _;
    }

    modifier onlyContract(address contractAddress) {
        _onlyContract(contractAddress);
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

    function _onlyContract(address contractAddress) private view {
        require(Address.isContract(contractAddress), "Invalid contract address");
    }

    function _onlyApprovedProvider(address provider) internal view {
        require(approvedProviders[provider], "Provider not approved");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount must be greater than 0");
    }

    function _validPoolId(uint256 poolId) internal view {
        require(_exists(poolId), "Pool does not exist");
    }
}
