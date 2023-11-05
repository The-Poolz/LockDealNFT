// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealNFTModifiers.sol";
import "../interfaces/IInnerWithdraw.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IBeforeTransfer.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
import {ModifierLocals} from "@spherex-xyz/contracts/src/ISphereXEngine.sol";
 

abstract contract LockDealNFTInternal is SphereXProtected, LockDealNFTModifiers {
    function _transfer(address from, address to, uint256 poolId) internal override sphereXGuardInternal(0xb1864345) {
        if (
            from != address(0) &&
            ERC165Checker.supportsInterface(address(poolIdToProvider[poolId]), type(IBeforeTransfer).interfaceId)
        ) {
            IBeforeTransfer(address(poolIdToProvider[poolId])).beforeTransfer(from, to, poolId);
        }
        // check for split and withdraw transfers
        if (!(approvedContracts[to] || approvedContracts[from])) {
            require(approvedPoolUserTransfers[from], "Pool transfer not approved by user");
            require(
                vaultManager.vaultIdToTradeStartTime(poolIdToVaultId[poolId]) < block.timestamp,
                "Can't transfer before trade start time"
            );
        }
        super._transfer(from, to, poolId);
    }

    modifier sphereXGuardInternal_mint() {
        ModifierLocals memory locals = _sphereXValidateInternalPre(0x1ea2d3dc);
        _;
        _sphereXValidateInternalPost(-0x1ea2d3dc, locals);
    }

    /// @param owner The address to assign the token to
    /// @param provider The address of the provider assigning the token
    /// @return newPoolId The ID of the pool
    function _mint(address owner, IProvider provider) internal sphereXGuardInternal_mint returns (uint256 newPoolId) {
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

    function _handleReturn(uint256 poolId, address from, bool isFinal) internal sphereXGuardInternal(0x32cf2448) {
        if (!isFinal) {
            _transfer(address(this), from, poolId);
        }
    }

    function _withdrawFromVault(uint256 poolId, uint256 withdrawnAmount, address from) internal sphereXGuardInternal(0x1d6d6d89) {
        if (withdrawnAmount > 0) {
            vaultManager.withdrawByVaultId(poolIdToVaultId[poolId], from, withdrawnAmount);
            emit MetadataUpdate(poolId);
            emit TokenWithdrawn(poolId, from, withdrawnAmount, _getData(poolId).params[0]);
        }
    }

    function _withdraw(address from, uint256 poolId) internal sphereXGuardInternal(0xb5e20586) returns (bool isFinal) {
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
    function _split(uint256 poolId, address from, bytes calldata data) internal sphereXGuardInternal(0x96da225d) returns (bool isFinal) {
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
    ) private notZeroAddress(newOwner) notZeroAmount(ratio) sphereXGuardInternal(0xaa31460b) returns (bool isFinal) {
        require(ratio <= 1e21, "split amount exceeded");
        SplitLocals memory locals;
        locals.provider = poolIdToProvider[poolId];
        locals.newPoolId = _mint(newOwner, locals.provider);
        poolIdToVaultId[locals.newPoolId] = poolIdToVaultId[poolId];
        locals.provider.split(poolId, locals.newPoolId, ratio);
        isFinal = locals.provider.getParams(poolId)[0] == 0;
        emit PoolSplit(poolId, from, locals.newPoolId, newOwner, _getData(poolId).params[0], _getData(locals.newPoolId).params[0]);
        emit MetadataUpdate(poolId);
    }
}
