// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTModifiers, IERC721Receiver {

    constructor(address _vaultManager, string memory _baseURI) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IFullVault(_vaultManager);
        approvedProviders[address(this)] = true;
        baseURI = _baseURI;
        //_registerInterface(_INTERFACE_ID_ERC2981); //TODO add IERC165 on Issue #226
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
        address from,
        uint256 poolId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(this), "invalid nft contract");
        if (from != address(0x0)) {
            (uint withdrawnAmount, bool isFinal) = poolIdToProvider[poolId].withdraw(provider, from, poolId, data);
            if (withdrawnAmount > 0) {
                vaultManager.withdrawByVaultId(
                    poolIdToVaultId[poolId],
                    from,
                    withdrawnAmount
                );
            }

            if (!isFinal) {
                transferFrom(address(this), from, poolId);
            }
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @dev Splits a pool into two pools with adjusted amounts
    /// @param poolId The ID of the pool to split
    /// @param ratio The ratio of funds to split into the new pool
    /// @param newOwner The address to assign the new pool to
    function split(
        uint256 poolId,
        uint256 ratio,
        address newOwner
    ) external onlyPoolOwner(poolId) notZeroAmount(ratio) returns(uint256 newPoolId, bool isFinal) {
        require(ratio <= 1e18, "split amount exceeded");
        IProvider provider = poolIdToProvider[poolId];
        newPoolId = _mint(newOwner, provider);
        poolIdToVaultId[newPoolId] = poolIdToVaultId[poolId];
        provider.split(poolId, newPoolId, ratio);
        uint256 leftAmount = provider.getParams(poolId)[0];
        isFinal = leftAmount == 0;
        emit MetadataUpdate(poolId);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(
        address owner,
        IProvider provider
    ) internal returns (uint256 newPoolId) {
        newPoolId = totalSupply();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
        emit MintInitiated(provider);
    }

    function updateProviderMetadata(uint256 poolId) external onlyApprovedProvider {
        emit MetadataUpdate(poolId);
    }

    function updateAllMetadata() external onlyOwner {
        emit MetadataUpdate(type(uint256).max);
    }

    function withdrawFromProvider(address from, uint256 poolId) public onlyApprovedProvider {
        transferFrom(msg.sender, from, poolId);
        transferFromProvider(from, poolId);
    }

    ///@dev don't use it if the provider is the owner or an approved caller
    function transferFromProvider(
        address from,
        uint256 poolId
    ) public onlyApprovedProvider {
        _approve(msg.sender, poolId);
        safeTransferFrom(from, address(this), poolId);
    }
}
