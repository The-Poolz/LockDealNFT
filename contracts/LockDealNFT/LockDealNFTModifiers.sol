// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealState.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LockDealNFTModifiers is LockDealState, Ownable {
    modifier onlyApprovedProvider() {
        _onlyApprovedProvider();
        _;
    }

    modifier onlyOwnerOrAdmin(uint256 poolId) {
        _onlyOwnerOrAdmin(poolId);
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

    function _notZeroAddress(address _address) private pure {
        require(_address != address(0x0), "Zero Address is not allowed");
    }

    function _onlyContract(address contractAddress) private view {
        require(
            Address.isContract(contractAddress),
            "Invalid contract address"
        );
    }

    function _onlyOwnerOrAdmin(uint256 poolId) internal view {
        require(
            msg.sender == ownerOf(poolId) || msg.sender == owner(),
            "invalid caller address"
        );
    }

    function _onlyApprovedProvider() internal view {
        require(approvedProviders[msg.sender], "Provider not approved");
    }
    
    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount should be greater than 0");
    }
}
