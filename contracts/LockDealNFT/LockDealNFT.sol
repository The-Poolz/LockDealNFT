// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../ProviderInterface/IProvider.sol";

contract LockDealNFT is LockDealNFTModifiers {
    using Counters for Counters.Counter;

    constructor(address _vaultManager) ERC721("LockDealNFT", "LDNFT") {
        require(_vaultManager != address(0x0), "invalid vault manager address");
        vaultManager = IVaultManager(_vaultManager);
        approvedProviders[address(this)] = true;
    }

    function exist(uint256 poolId) external view returns (bool) {
        return _exists(poolId);
    }

    function mint(
        address owner,
        address token,
        address from,
        uint256 amount
    )
        public
        onlyApprovedProvider
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        approvedAmount(token, from, amount)
        returns (uint256 poolId)
    {
        poolId = _mint(owner, msg.sender);
        poolIdToVaultId[poolId] = vaultManager.DepositByToken(token, from, amount);
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
        vaultManager.WithdrawByVaultId(
            poolIdToVaultId[poolId],
            ownerOf(poolId),
            withdrawnAmount
        );
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
        newPoolId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }
}
