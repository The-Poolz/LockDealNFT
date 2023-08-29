// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTInternal.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTInternal, IERC721Receiver {
    constructor(address _vaultManager, string memory _baseURI) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
        approvedProviders[address(this)] = true;
        baseURI = _baseURI;
    }

    function mintForProvider(
        address owner,
        IProvider provider
    ) external onlyApprovedProvider(provider) notZeroAddress(owner) returns (uint256 poolId) {
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
        onlyApprovedProvider(provider)
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        require(amount < type(uint256).max, "amount is too big");
        poolId = _mint(owner, provider);
        poolIdToVaultId[poolId] = vaultManager.depositByToken(token, from, amount);
    }

    function copyVaultId(
        uint256 fromId,
        uint256 toId
    ) external onlyApprovedProvider(IProvider(msg.sender)) validPoolId(fromId) validPoolId(toId) {
        poolIdToVaultId[toId] = poolIdToVaultId[fromId];
    }

    /// @dev Sets the approved status of a provider
    /// @param provider The address of the provider
    /// @param status The new approved status (true or false)
    function setApprovedProvider(IProvider provider, bool status) external onlyOwner onlyContract(address(provider)) {
        approvedProviders[address(provider)] = status;
        emit ProviderApproved(provider, status);
    }

    function approvePoolTransfers(bool status) external {
        require(approvedPoolUserTransfers[msg.sender] != status, "status is the same as before");
        approvedPoolUserTransfers[msg.sender] = status;
    }

    ///@dev withdraw implementation
    function onERC721Received(
        address,
        address from,
        uint256 poolId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(this), "invalid nft contract");
        _handleReturn(poolId, from, data.length > 0 ? _split(poolId, from, data) : _withdrawERC20(from, poolId));
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateAllMetadata() external onlyOwner {
        emit MetadataUpdate(type(uint256).max);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(
            keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked(newBaseURI)),
            "can't set the same baseURI"
        );
        string memory oldBaseURI = baseURI;
        baseURI = newBaseURI;
        emit BaseURIChanged(oldBaseURI, newBaseURI);
    }
}