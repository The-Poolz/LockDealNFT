// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";

contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor(address _vaultManager) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
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
        returns (uint256 poolId)
    {
        if (tokenToVaultId[token] == 0) {
            tokenToVaultId[token] = vaultManager.CreateNewVault(token);
        }
        poolId = _mint(owner, msg.sender);
        poolIdToVaultId[poolId] = tokenToVaultId[token];
        poolIdToProvider[poolId] = msg.sender;
        vaultManager.DepositeByVaultId(tokenToVaultId[token], owner, amount);
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
        vaultManager.WithdrawByVaultId(
            poolIdToVaultId[poolId],
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
        newPoolId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }
}
