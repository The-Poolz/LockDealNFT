// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IBeforeTransfer.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IInnerWithdraw.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

abstract contract LockDealNFTInternal is LockDealNFTModifiers, FirewallConsumer {
    function _update(
        address to,
        uint256 poolId,
        address auth
    ) internal override firewallProtectedSig(0x30e0789e) returns (address from) {
        if (auth != address(0) && ERC165Checker.supportsInterface(address(poolIdToProvider[poolId]), type(IBeforeTransfer).interfaceId)) {
            IBeforeTransfer(address(poolIdToProvider[poolId])).beforeTransfer(auth, to, poolId);
        }
        // check for split and withdraw transfers
        if (auth != address(0) && !(approvedContracts[to] || approvedContracts[auth])) {
            require(approvedPoolUserTransfers[auth], "Pool transfer not approved by user");
            require(
                vaultManager.vaultIdToTradeStartTime(poolIdToVaultId[poolId]) < block.timestamp,
                "Can't transfer before trade start time"
            );
        }
        from = super._update(to, poolId, auth);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(address owner, IProvider provider)
        internal
        firewallProtectedSig(0x3c99ae44)
        returns (uint256 newPoolId)
    {
        newPoolId = totalSupply();
        _safeMint(owner, newPoolId);
        poolIdToProvider[newPoolId] = provider;
    }

    function _parseData(bytes calldata data, address from) internal pure returns (uint256 ratio, address newOwner) {
        (ratio, newOwner) = data.length == 32
            ? (abi.decode(data, (uint256)), from)
            : abi.decode(data, (uint256, address));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _handleReturn(uint256 poolId, address from, bool isFinal) internal firewallProtectedSig(0x1d50d0db) {
        if (!isFinal) {
            _transfer(address(this), from, poolId);
        }
    }

    function _withdrawFromVault(uint256 poolId, uint256 withdrawnAmount, address from)
        internal
        firewallProtectedSig(0x05d6a92f)
    {
        if (withdrawnAmount > 0) {
            vaultManager.withdrawByVaultId(poolIdToVaultId[poolId], from, withdrawnAmount);
            emit MetadataUpdate(poolId);
            emit TokenWithdrawn(poolId, from, withdrawnAmount, _getData(poolId).params[0]);
        }
    }

    function _withdraw(address from, uint256 poolId) internal firewallProtectedSig(0xb790a77b) returns (bool isFinal) {
        uint256 withdrawnAmount;
        IProvider provider = poolIdToProvider[poolId];
        (withdrawnAmount, isFinal) = provider.withdraw(poolId);
        if (ERC165Checker.supportsInterface(address(provider), type(IInnerWithdraw).interfaceId)) {
            withdrawnAmount = 0;
            uint256[] memory ids = IInnerWithdraw(address(provider)).getInnerIdsArray(poolId);
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                require(ownerOf(id) == address(poolIdToProvider[poolId]), "invalid inner id");
                _withdraw(from, id);
            }
        }
        _withdrawFromVault(poolId, withdrawnAmount, from);
    }

    /// @dev Splits a pool into two pools with adjusted amounts
    /// @param poolId The ID of the pool to split
    function _split(
        uint256 poolId,
        address from,
        bytes calldata data
    ) internal firewallProtectedSig(0x1746b892) returns (bool isFinal) {
        (uint256 ratio, address newOwner) = _parseData(data, from);
        isFinal = _split(poolId, from, ratio, newOwner);
    }

    struct SplitLocals {
        IProvider provider;
        uint256 newPoolId;
    }

    function _split(
        uint256 poolId,
        address from,
        uint256 ratio,
        address newOwner
    ) private notZeroAddress(newOwner) notZeroAmount(ratio) returns (bool isFinal) {
        require(ratio <= 1e21, "split amount exceeded");
        SplitLocals memory locals;
        locals.provider = poolIdToProvider[poolId];
        locals.newPoolId = _mint(newOwner, locals.provider);
        poolIdToVaultId[locals.newPoolId] = poolIdToVaultId[poolId];
        locals.provider.split(poolId, locals.newPoolId, ratio);
        isFinal = locals.provider.getParams(poolId)[0] == 0;
        uint256 splitLeftAmount = _getData(poolId).params[0];
        emit PoolSplit(poolId, from, locals.newPoolId, newOwner, splitLeftAmount, _getData(locals.newPoolId).params[0]);
        emit MetadataUpdate(poolId);
    }
}
