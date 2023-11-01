// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTInternal.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

/// @title LockDealNFT contract
/// @notice Implements a non-fungible token (NFT) contract for locking deals
contract LockDealNFT is LockDealNFTInternal, IERC721Receiver {
    constructor(address _vaultManager, string memory _baseURI) ERC721("LockDealNFT", "LDNFT") {
        _notZeroAddress(_vaultManager);
        vaultManager = IVaultManager(_vaultManager);
        approvedContracts[address(this)] = true;
        baseURI = _baseURI;
    }

    function mintForProvider(
        address owner,
        IProvider provider
    ) external onlyApprovedContract(address(provider)) notZeroAddress(owner) sphereXGuardExternal(0x2abf27c7) returns (uint256 poolId) {
        poolId = _mint(owner, provider);
    }

    function mintAndTransfer(
        address owner,
        address token,
        uint256 amount,
        IProvider provider
    )
        public
        onlyApprovedContract(address(provider))
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        sphereXGuardPublic(0xf27df696, 0x27608c36) returns (uint256 poolId)
    {
        poolId = _mint(owner, provider);
        IERC20(token).approve(address(vaultManager), amount);
        poolIdToVaultId[poolId] = vaultManager.depositByToken(token, amount);
    }

    function safeMintAndTransfer(
        address owner,
        address token,
        address from,
        uint256 amount,
        IProvider provider,
        bytes calldata data
    )
        public
        onlyApprovedContract(address(provider))
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        sphereXGuardPublic(0xd17162eb, 0x604e38ed) returns (uint256 poolId)
    {
        poolId = _mint(owner, provider);
        poolIdToVaultId[poolId] = vaultManager.safeDeposit(token, amount, from, data);
    }

    function cloneVaultId(
        uint256 destinationPoolId,
        uint256 sourcePoolId
    ) external onlyApprovedContract(msg.sender) validPoolId(destinationPoolId) validPoolId(sourcePoolId) sphereXGuardExternal(0x90aad81c) {
        poolIdToVaultId[destinationPoolId] = poolIdToVaultId[sourcePoolId];
    }

    /// @dev Sets the approved status of a contract
    /// @param contractAddress The address of the contract
    /// @param status The new approved status (true or false)
    function setApprovedContract(address contractAddress, bool status) external onlyOwner onlyContract(contractAddress) sphereXGuardExternal(0x6529f919) {
        approvedContracts[contractAddress] = status;
        emit ContractApproved(contractAddress, status);
    }

    function approvePoolTransfers(bool status) external sphereXGuardExternal(0x46314c85) {
        require(approvedPoolUserTransfers[msg.sender] != status, "status is the same as before");
        approvedPoolUserTransfers[msg.sender] = status;
    }

    ///@dev withdraw implementation
    function onERC721Received(
        address,
        address from,
        uint256 poolId,
        bytes calldata data
    ) external override sphereXGuardExternal(0xf7889b50) returns (bytes4) {
        require(msg.sender == address(this), "invalid nft contract");
        _handleReturn(poolId, from, data.length > 0 ? _split(poolId, from, data) : _withdraw(from, poolId));
        return IERC721Receiver.onERC721Received.selector;
    }

    function updateAllMetadata() external onlyOwner sphereXGuardExternal(0x589dadff) {
        emit MetadataUpdate(type(uint256).max);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) sphereXGuardPublic(0xfc7d9f6b, 0x23b872dd) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, "");
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner sphereXGuardExternal(0x105f803f) {
        require(
            keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked(newBaseURI)),
            "can't set the same baseURI"
        );
        string memory oldBaseURI = baseURI;
        baseURI = newBaseURI;
        emit BaseURIChanged(oldBaseURI, newBaseURI);
    }
}
