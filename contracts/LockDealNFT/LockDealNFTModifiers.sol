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
}
