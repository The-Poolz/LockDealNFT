// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiWithdrawState.sol";
import "../../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Array.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MultiWithdrawProvider is MultiWithdrawState, ERC721Holder, IInnerWithdraw {
    struct Vault {
        uint256 vaultId;
        uint256 amount;
    }

    constructor(ILockDealNFT nftContract, IProvider _dealProvider, uint256 _maxPoolsPerTx) {
        name = "MultiWithdrawProvider";
        lockDealNFT = nftContract;
        maxPoolsPerTx = _maxPoolsPerTx;
        dealProvider = _dealProvider;
    }

    function createNewPool(address _owner) external returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(_owner, IProvider(address(this)));
    }

    function withdraw(uint256) external pure returns (uint256 withdrawnAmount, bool isFinal) {
        return (type(uint256).max, true);
    }

    function getInnerIdsArray(uint256, address from) external override returns (uint256[] memory ids) {
        (
            uint256[] memory uniqueVaultIds,
            uint256[] memory totalAmounts,
            uint256[] memory poolIds
        ) = getUniqueVaultIdsAndTotalAmounts(from);
        ids = new uint256[](uniqueVaultIds.length);
        for (uint256 i = 0; i < uniqueVaultIds.length; ++i) {
            uint256 poolId = lockDealNFT.mintForProvider(from, dealProvider);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = totalAmounts[i];
            dealProvider.registerPool(poolId, amounts);
            lockDealNFT.copyVaultId(poolIds[i], poolId);
            ids[i] = poolId;
        }
    }

    function getAllVaults(address from) public returns (Vault[] memory vaults, uint256[] memory poolIds) {
        uint256 totalPools = lockDealNFT.balanceOf(from);
        vaults = new Vault[](totalPools);
        poolIds = new uint256[](totalPools);
        for (uint256 i = 0; i < totalPools; ++i) {
            uint256 _poolId = lockDealNFT.tokenOfOwnerByIndex(from, i);
            vaults[i].vaultId = lockDealNFT.getData(_poolId).vaultId;
            vaults[i].amount = lockDealNFT.getWithdrawableAmount(_poolId);
            lockDealNFT.poolIdToProvider(_poolId).withdraw(_poolId);
            poolIds[i] = _poolId;
        }
    }

    function getUniqueVaultIdsAndTotalAmounts(
        address from
    ) public returns (uint256[] memory uniqueVaultIds, uint256[] memory vaultTotalAmounts, uint256[] memory ids) {
        (Vault[] memory vaults, uint256[] memory poolIds) = getAllVaults(from);
        uint256 length = vaults.length;
        Vault[] memory uniqueVaults = new Vault[](length);
        ids = new uint256[](length);
        uint256 uniqueCount = 0;
        for (uint256 i = 0; i < length; ++i) {
            bool found = false;
            for (uint256 j = 0; j < uniqueCount; ++j) {
                if (uniqueVaults[j].vaultId == vaults[i].vaultId) {
                    uniqueVaults[j].amount += vaults[i].amount;
                    ids[j] = poolIds[i];
                    found = true;
                    break;
                }
            }
            if (!found) {
                uniqueVaults[uniqueCount] = vaults[i];
                ++uniqueCount;
            }
        }
        uniqueVaultIds = new uint256[](uniqueCount);
        vaultTotalAmounts = new uint256[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; ++i) {
            uniqueVaultIds[i] = uniqueVaults[i].vaultId;
            vaultTotalAmounts[i] = uniqueVaults[i].amount;
        }
        ids = Array.KeepNElementsInArray(ids, uniqueCount);
    }
}
