// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";

contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor() ERC721("LockDealNFT", "LDNFT") {
        approvedProviders[address(this)] = true;
    }

    function mint(
        address owner,
        address token,
        uint256 amount
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256)
    {
        return _mint(owner, msg.sender);
    }

    function setApprovedProvider(
        address provider,
        bool status
    ) external onlyOwner onlyContract(provider) {
        approvedProviders[provider] = status;
    }

    function withdraw(
        uint256 poolId
    ) external onlyOwnerOrAdmin(poolId) returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = IProvider(poolIdToProvider[poolId]).withdraw(poolId);
        if (isFinal) {
            _burn(poolId);
        }
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

    function _mint(
        address owner,
        address provider
    ) internal returns (uint256 newPoolId) {
        newPoolId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }
}
