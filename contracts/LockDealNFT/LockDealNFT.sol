// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "./ILockDealNFTEvents.sol";
import "../ProviderInterface/IProvider.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTModifiers, ILockDealNFTEvents {
    using Counters for Counters.Counter;

    constructor(address _vaultManager) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
        approvedProviders[address(this)] = true;
    }

    /// @dev Checks if a pool with the given ID exists
    /// @param poolId The ID of the pool
    /// @return boolean indicating whether the pool exists or not
    function exist(uint256 poolId) external view returns (bool) {
        return _exists(poolId);
    }

    function tokenOf(uint256 poolId) external view returns (address token) {
        token = vaultManager.vaultIdToTokenAddress(poolIdToVaultId[poolId]);
    }

    function mint(
        address owner,
        address token,
        address from,
        uint256 amount,
        address provider
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAddress(provider)
        returns (uint256 poolId)
    {
        if(provider != msg.sender) {
            _onlyApprovedProvider(provider);
        }
        poolId = _mint(owner, provider);
        poolIdToVaultId[poolId] = vaultManager.depositByToken(token, from, amount);
    }

    /// @dev Sets the approved status of a provider
    /// @param provider The address of the provider
    /// @param status The new approved status (true or false)
    function setApprovedProvider(
        address provider,
        bool status
    ) external onlyOwner onlyContract(provider) {
        approvedProviders[provider] = status;
        emit ProviderApproved(provider, status);
    }

    /// @dev Withdraws funds from a pool and updates the vault accordingly
    /// @param poolId The ID of the pool
    /// @return withdrawnAmount The amount of funds withdrawn from the pool
    /// @return isFinal A boolean indicating if the withdrawal is the final one
    function withdraw(
        uint256 poolId
    ) external onlyOwnerOrAdmin(poolId) returns (uint256 withdrawnAmount, bool isFinal) {
        address provider = poolIdToProvider[poolId];
        (withdrawnAmount, isFinal) = IProvider(provider).withdraw(poolId);
        
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
        uint256 newPoolId = _mint(newOwner, poolIdToProvider[poolId]);
        IProvider(poolIdToProvider[poolId]).split(
            poolId,
            newPoolId,
            splitAmount
        );
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(
        address owner,
        address provider
    ) internal returns (uint256 newPoolId) {
        newPoolId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
        emit MintInitiated(provider);
    }
}