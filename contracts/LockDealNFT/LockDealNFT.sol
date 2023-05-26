// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";
import "../interface/IVaultFactory.sol";
import "../interface/IVault.sol";

contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor(address _vaultFactory) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultFactory != address(0x0), "invalid vault factory address");
        vaultFactory = _vaultFactory;
        approvedProviders[address(this)] = true;
    }

    function mint(
        address owner,
        address creator,
        address token,
        uint256 amount
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAddress(tokenToVault[token])
        notZeroAddress(creator)
        returns (uint256 poolId)
    {
        IVault(tokenToVault[token]).deposit(creator, amount);
        poolId = _mint(owner, msg.sender);
    }

    function createNewVault(
        address token
    ) external onlyOwner notZeroAddress(token) {
        tokenToVault[token] = IVaultFactory(vaultFactory).CreateNewVault(token);
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
        IVault(poolIdToVault[poolId]).withdraw(
            ownerOf(poolId),
            withdrawnAmount
        );
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) external onlyOwnerOrAdmin(poolId) {
        uint256 newPoolId = _mint(newOwner, poolIdToProvider[poolId]);
        IProvider(poolIdToProvider[newPoolId]).split(
            poolId,
            newPoolId,
            splitAmount
        );
    }

    function _mint(
        address owner,
        address provider
    ) internal returns (uint256 newPoolId) {
        newPoolId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }
}
