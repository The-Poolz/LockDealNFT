// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTState.sol";

abstract contract LockDealNFTModifiers is LockDealNFTState {
    modifier onlyApprovedProvider() {
        _onlyApprovedProvider(IProvider(msg.sender));
        _;
    }

    modifier onlyPoolOwner(uint256 poolId) {
        _onlyPoolOwner(poolId);
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

    modifier validPoolId(uint256 poolId){
        _validPoolId(poolId);
        _;
    }

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _onlyContract(address contractAddress) private view {
        require(
            Address.isContract(contractAddress),
            "Invalid contract address"
        );
    }

    function _onlyPoolOwner(uint256 poolId) internal view {
        require(msg.sender == ownerOf(poolId), "Caller is not the pool owner");
    }

    function _onlyApprovedProvider(IProvider provider) internal view {
        require(approvedProviders[address(provider)], "Provider not approved");
    }

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount must be greater than 0");
    }

    function _validPoolId(uint256 poolId) internal view {
        require(_exists(poolId), "Pool does not exist");
    }
}
