// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";

contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor() ERC721("LockDealNFT", "LDNFT") {
        approvedProviders[address(this)] = true;
    }

    function mint(address to) public onlyApprovedProvider notZeroAddress(to) returns (uint256){
        return _mint(to, msg.sender);
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
        uint256 newPoolId = _mint(newOwner, poolIdToProvider[poolId]);
        IProvider(poolIdToProvider[poolId]).split(
            poolId,
            newPoolId,
            splitAmount
        );
    }
    
    function _mint(address to, address provider) internal returns (uint256 newPoolId){
        newPoolId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }
}
