// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";

contract LockDealNFT is LockDealNFTModifiers, IProvider {
    using Counters for Counters.Counter;

    constructor() ERC721("LockDealNFT", "LDNFT") {}

    function mint(address to) public onlyApprovedProvider {
        _tokenIdCounter.increment();

        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        poolIdToProvider[newItemId] = msg.sender;
    }

    function setApprovedProvider(
        address provider,
        bool status
    ) external onlyOwner onlyContract(provider) {
        approvedProviders[provider] = status;
    }

    function withdraw(
        uint256 poolId
    ) external onlyOwnerOrAdmin(poolId) returns (uint256 withdrawnAmount) {
        withdrawnAmount = IProvider(poolIdToProvider[poolId]).withdraw(poolId);
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) external onlyOwnerOrAdmin(poolId) {
        IProvider(poolIdToProvider[poolId]).split(
            poolId,
            splitAmount,
            newOwner
        );
    }
}
