// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";

abstract contract LockDealNFTInternal is LockDealNFTModifiers {
    function _transfer(address from, address to, uint256 poolId) internal override {
        // check for split and withdraw transfers
        if (!(approvedProviders[IProvider(to)] || approvedProviders[IProvider(from)])) {
            require(approvedPoolUserTransfers[from], "Pool transfer not approved by user");
            require(
                vaultManager.vaultIdToTradeStartTime(poolIdToVaultId[poolId]) < block.timestamp,
                "Can't transfer before trade start time"
            );
        }
        super._transfer(from, to, poolId);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(address owner, IProvider provider) internal returns (uint256 newPoolId) {
        newPoolId = totalSupply();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
        emit MintInitiated(provider);
    }

    function _parseData(bytes calldata data, address from) internal pure returns (uint256 ratio, address newOwner) {
        (ratio, newOwner) = data.length == 32
            ? (abi.decode(data, (uint256)), from)
            : abi.decode(data, (uint256, address));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _handleReturn(uint256 poolId, address from, bool isFinal) internal {
        if (!isFinal) {
            _transfer(address(this), from, poolId);
        }
    }

    function _withdrawFromVault(uint256 poolId, uint256 withdrawnAmount, address from) internal {
        if (withdrawnAmount > 0) {
            vaultManager.withdrawByVaultId(poolIdToVaultId[poolId], from, withdrawnAmount);
            emit MetadataUpdate(poolId);
            emit TokenWithdrawn(poolId, from, withdrawnAmount, getData(poolId).params[0]);
        }
    }

    function _withdrawERC20(address from, uint256 poolId) internal returns (bool isFinal) {
        uint256 withdrawnAmount;
        (withdrawnAmount, isFinal) = poolIdToProvider[poolId].withdraw(poolId);
        if (withdrawnAmount == type(uint256).max) {
            withdrawnAmount = 0;
            uint256[] memory ids = IInnerWithdraw(address(poolIdToProvider[poolId])).getInnerIdsArray(poolId);
            for (uint256 i = 0; i < ids.length; ++i) {
                _withdrawERC20(from, ids[i]);
            }
        }
        _withdrawFromVault(poolId, withdrawnAmount, from);
    }

    /// @dev Splits a pool into two pools with adjusted amounts
    /// @param poolId The ID of the pool to split
    function _split(uint256 poolId, address from, bytes calldata data) internal returns (bool isFinal) {
        (uint256 ratio, address newOwner) = _parseData(data, from);
        isFinal = _split(poolId, from, ratio, newOwner);
    }

    function _split(
        uint256 poolId,
        address from,
        uint256 ratio,
        address newOwner
    ) private notZeroAddress(newOwner) notZeroAmount(ratio) returns (bool isFinal) {
        require(ratio <= 1e18, "split amount exceeded");
        IProvider provider = poolIdToProvider[poolId];
        uint256 newPoolId = _mint(newOwner, provider);
        poolIdToVaultId[newPoolId] = poolIdToVaultId[poolId];
        provider.split(poolId, newPoolId, ratio);
        isFinal = provider.getParams(poolId)[0] == 0;
        emit PoolSplit(poolId, from, newPoolId, newOwner, getData(poolId).params[0], getData(newPoolId).params[0]);
        emit MetadataUpdate(poolId);
    }
}
