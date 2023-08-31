// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IVaultManager.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Array.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILockDealNFTEvents.sol";
import "../interfaces/ILockDealNFT.sol";

/**
 * @title LockDealNFTState
 * @dev An abstract contract that defines the state variables and mappings for the LockDealNFT contract.
 */
abstract contract LockDealNFTState is ERC721Enumerable, ILockDealNFTEvents, Ownable, IERC4906, ILockDealNFT, IERC2981 {
    string public baseURI;
    IVaultManager public vaultManager;

    mapping(uint256 => IProvider) public poolIdToProvider;
    mapping(uint256 => uint256) public poolIdToVaultId;
    mapping(address => bool) public approvedPoolUserTransfers;
    mapping(IProvider => bool) public approvedProviders;

    function getData(uint256 poolId) public view returns (BasePoolInfo memory poolInfo) {
        if (_exists(poolId)) {
            IProvider provider = poolIdToProvider[poolId];
            poolInfo = BasePoolInfo(
                provider,
                poolId,
                poolIdToVaultId[poolId],
                ownerOf(poolId),
                tokenOf(poolId),
                provider.getParams(poolId)
            );
        }
    }

    function getUserDataByTokens(
        address user,
        address[] calldata tokens,
        uint256 from,
        uint256 to
    ) public view returns (BasePoolInfo[] memory userPoolInfo) {
        require(from <= to, "Invalid range");
        require(to < balanceOf(user, tokens), "Range greater than user pool count");
        userPoolInfo = new BasePoolInfo[](to - from + 1);
        uint256 userPoolIndex = 0;
        for (uint256 i = from; i <= to; ++i) {
            uint256 poolId = tokenOfOwnerByIndex(user, tokens, i);
            userPoolInfo[userPoolIndex++] = getData(poolId);
        }
    }

    function tokenOf(uint256 poolId) public view returns (address token) {
        token = vaultManager.vaultIdToTokenAddress(poolIdToVaultId[poolId]);
    }

    function getWithdrawableAmount(uint256 poolId) external view returns (uint256 withdrawalAmount) {
        if (_exists(poolId)) {
            withdrawalAmount = poolIdToProvider[poolId].getWithdrawableAmount(poolId);
        }
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        (receiver, royaltyAmount) = vaultManager.royaltyInfo(poolIdToVaultId[tokenId], salePrice);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(ILockDealNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    ///@dev balanceOf with tokens association
    function balanceOf(address owner, address[] calldata tokens) public view returns (uint256 balance) {
        uint256 fullBalanceOf = balanceOf(owner);
        for (uint256 i = 0; i < fullBalanceOf; ++i) {
            if (Array.isInArray(tokens, tokenOf(tokenOfOwnerByIndex(owner, i)))) {
                ++balance;
            }
        }
    }

    ///@dev tokenOfOwnerByIndex with tokens association
    function tokenOfOwnerByIndex(
        address owner,
        address[] calldata tokens,
        uint256 index
    ) public view returns (uint256 poolId) {
        uint256 length = balanceOf(owner, tokens);
        require(index < length, "index out of bounds");
        uint256 fullBalanceOf = balanceOf(owner);
        uint256 j = 0;
        for (uint256 i = 0; i < fullBalanceOf; ++i) {
            poolId = tokenOfOwnerByIndex(owner, i);
            if (Array.isInArray(tokens, tokenOf(poolId)) && j++ == index) {
                return poolId;
            }
        }
    }
}
