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
    mapping(address => bool) public approvedContracts;

    function getData(uint256 poolId) public view returns (BasePoolInfo memory poolInfo) {
        if (_exists(poolId)) {
            poolInfo = _getData(poolId);
        }
    }

    function getFullData(uint256 poolId) public view returns (BasePoolInfo[] memory poolInfo) {
        if (!_exists(poolId)) {
            uint256[] memory poolIds = poolIdToProvider[poolId].getSubProvidersPoolIds(poolId);
            uint256 length = poolIds.length;
            for (uint256 i = 0; i < length; ++i) {
                poolInfo[i] = _getData(poolIds[i]);
            }
        }
    }

    function _getData(uint256 poolId) internal view returns (BasePoolInfo memory poolInfo) {
        IProvider provider = poolIdToProvider[poolId];
        poolInfo = BasePoolInfo(
            provider,
            provider.name(),
            poolId,
            poolIdToVaultId[poolId],
            ownerOf(poolId),
            tokenOf(poolId),
            provider.getParams(poolId)
        );
    }

    /// @dev Retrieves user data by tokens between a specified index range.
    /// This is used by the front-end to fetch NFTs linked to a predefined set of supported tokens.
    /// It's primarily queried off-chain, so gas costs are not a concern here.
    /// @param user The address of the user.
    /// @param tokens The list of supported tokens.
    /// @param from Starting index for the query.
    /// @param to Ending index for the query.
    /// @return userPoolInfo An array containing pool information for the user's NFTs within the specified range.
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

    /// @dev Returns the balance of NFTs owned by an address, which are also in the provided tokens list.
    /// @param owner The address of the owner.
    /// @param tokens List of supported tokens to filter by.
    /// @return balance The number of NFTs owned by the address and present in the tokens list.
    function balanceOf(address owner, address[] calldata tokens) public view returns (uint256 balance) {
        uint256 fullBalanceOf = balanceOf(owner);
        for (uint256 i = 0; i < fullBalanceOf; ++i) {
            if (Array.isInArray(tokens, tokenOf(tokenOfOwnerByIndex(owner, i)))) {
                ++balance;
            }
        }
    }

    /// @dev Retrieves a token ID owned by an address at a specific index, which is also in the provided tokens list.
    /// @param owner The address of the owner.
    /// @param tokens List of supported tokens to filter by.
    /// @param index The index to retrieve the token ID from.
    /// @return poolId The token ID owned by the address at the specified index.
    function tokenOfOwnerByIndex(
        address owner,
        address[] calldata tokens,
        uint256 index
    ) public view returns (uint256 poolId) {
        uint256 length = balanceOf(owner, tokens);
        require(index < length, "invalid poolId index by token association");
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
