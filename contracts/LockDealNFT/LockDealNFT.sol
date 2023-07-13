// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor(address _vaultManager) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
        approvedProviders[address(this)] = true;
    }

    function mintForProvider(
        address owner,
        IProvider provider
    )
        external
        onlyApprovedProvider
        notZeroAddress(owner)
        returns (uint256 poolId)
    {
        if (address(provider) != msg.sender) {
            _onlyApprovedProvider(provider);
        }
        poolId = _mint(owner, provider);
    }

    function mintAndTransfer(
        address owner,
        address token,
        address from,
        uint256 amount,
        IProvider provider
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        if (address(provider) != msg.sender) {
            _onlyApprovedProvider(provider);
        }
        poolId = _mint(owner, provider);
        poolIdToVaultId[poolId] = vaultManager.depositByToken(
            token,
            from,
            amount
        );
    }

    function copyVaultId(uint256 fromId, uint256 toId) external onlyApprovedProvider {
        _onlyApprovedProvider(IProvider(msg.sender));
        poolIdToVaultId[toId] = poolIdToVaultId[fromId];
    }

    /// @dev Sets the approved status of a provider
    /// @param provider The address of the provider
    /// @param status The new approved status (true or false)
    function setApprovedProvider(
        IProvider provider,
        bool status
    ) external onlyOwner onlyContract(address(provider)) {
        approvedProviders[address(provider)] = status;
        emit ProviderApproved(provider, status);
    }

    /// @dev Withdraws funds from a pool and updates the vault accordingly
    /// @param poolId The ID of the pool
    /// @return withdrawnAmount The amount of funds withdrawn from the pool
    /// @return isFinal A boolean indicating if the withdrawal is the final one
    function withdraw(
        uint256 poolId
    )
        external
        onlyOwnerOrAdmin(poolId)
        returns (uint256 withdrawnAmount, bool isFinal)
    {
        IProvider provider = poolIdToProvider[poolId];
        (withdrawnAmount, isFinal) = provider.withdraw(poolId);

        // in case of the sub-provider, the main provider will sum the data
        if (!approvedProviders[ownerOf(poolId)]) {
            vaultManager.withdrawByVaultId(
                poolIdToVaultId[poolId],
                ownerOf(poolId),
                withdrawnAmount
            );
        }

        if (isFinal) {
            _burn(poolId);
        }
    }

    /// @dev Splits a pool into two pools with adjusted amounts
    /// @param poolId The ID of the pool to split
    /// @param splitAmount The amount of funds to split into the new pool
    /// @param newOwner The address to assign the new pool to
    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) external onlyOwnerOrAdmin(poolId) {
        IProvider provider = poolIdToProvider[poolId];
        uint256 newPoolId = _mint(newOwner, provider);
        poolIdToVaultId[newPoolId] = poolIdToVaultId[poolId];
        provider.split(poolId, newPoolId, splitAmount);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(
        address owner,
        IProvider provider
    ) internal returns (uint256 newPoolId) {
        newPoolId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
        emit MintInitiated(provider);
    }
}
