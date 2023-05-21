// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interface/IProvider.sol";
import "../interface/IVault.sol";

contract LockDealNFT is LockDealNFTModifiers, IProvider {
    using Counters for Counters.Counter;

    constructor() ERC721("LockDealNFT", "LDNFT") {}

    function mint(address nftTo, address token, address tokensFrom, uint256 amount) public onlyApprovedProvider returns (uint256 newItemId) {
        require(TokenToVault[token] != address(0), "Token not supported");
        newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        HandleTransferIn(TokenToVault[token],tokensFrom,amount);
        _safeMint(nftTo, newItemId);
        poolIdToPoolInformation[newItemId] = PoolInformation(msg.sender, TokenToVault[token]);
    }

    function HandleTransferIn(address vault, address from, uint256 amount) internal
    {       
        IVault(vault).deposit(from, amount);
    }

    function HandleTransferOut(address vault, address to, uint256 amount) internal
    {
        IVault(vault).withdraw(to, amount);
    }
    
    function setApprovedProvider(
        address provider,
        bool status
    ) external onlyOwner onlyContract(provider) {
        approvedProviders[provider] = status;
    }

    function withdraw(
        uint256 poolId
    ) external onlyOwnerOrAdmin(poolId) returns (uint256 withdrawnAmount, bool isClosed) {
        (withdrawnAmount, isClosed) = IProvider(poolIdToPoolInformation[poolId].Provider).withdraw(poolId);
        HandleTransferOut(poolIdToPoolInformation[poolId].Vault, ownerOf(poolId), withdrawnAmount);
        if (isClosed) {
            _burn(poolId);
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) external onlyOwnerOrAdmin(poolId) {
        IProvider(poolIdToPoolInformation[poolId].Provider).split(
            poolId,
            splitAmount,
            newOwner
        );
    }
}
