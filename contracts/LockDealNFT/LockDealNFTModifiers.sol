// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealState.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LockDealNFTModifiers is LockDealState, Ownable {
    modifier onlyApprovedProvider() {
        require(approvedProviders[msg.sender], "Provider not approved");
        _;
    }

    modifier onlyOwnerOrAdmin(uint256 poolId) {
        require(
            msg.sender == ownerOf(poolId) || msg.sender == owner(),
            "invalid caller address"
        );
        _;
    }

    modifier onlyContract(address contractAddress) {
        require(
            Address.isContract(contractAddress),
            "Invalid contract address"
        );
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

    function _notZeroAmount(uint256 amount) private pure {
        require(amount > 0, "amount should be greater than 0");
    }
}
