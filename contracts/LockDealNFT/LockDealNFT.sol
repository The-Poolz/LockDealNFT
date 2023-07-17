// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTModifiers, IERC721Receiver {
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

    function copyVaultId(
        uint256 fromId,
        uint256 toId
    ) external onlyApprovedProvider validPoolId(fromId) validPoolId(toId) {
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

    ///@dev withdraw implementation
    function onERC721Received(
        address provider,
        address user,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(this), "invalid nft contract");
        if (provider == user) {
            (uint withdrawnAmount, bool isFinal) = poolIdToProvider[poolId]
                .withdraw(poolId);

            vaultManager.withdrawByVaultId(
                poolIdToVaultId[poolId],
                user,
                withdrawnAmount
            );

            if (!isFinal) {
                transferFrom(address(this), user, poolId);
            }
        }
        return IERC721Receiver.onERC721Received.selector;
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
