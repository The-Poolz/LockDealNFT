// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IVaultManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILockDealNFTEvents.sol";

/**
 * @title LockDealNFTState
 * @dev An abstract contract that defines the state variables and mappings for the LockDealNFT contract.
 */
abstract contract LockDealNFTState is ERC721Enumerable, ILockDealNFTEvents, Ownable {
    string public baseURI;
    IVaultManager public vaultManager;

    mapping(uint256 => IProvider) public poolIdToProvider;
    mapping(uint256 => uint256) public poolIdToVaultId;
    mapping(address => bool) public approvedProviders;

    function getData(
        uint256 poolId
    ) public view returns (BasePoolInfo memory poolInfo) {
        if (_exists(poolId)) {
            IProvider provider = poolIdToProvider[poolId];
            poolInfo = BasePoolInfo(
                provider,
                poolId,
                ownerOf(poolId),
                tokenOf(poolId),
                provider.getParams(poolId)
            );
        }
    }

    function getData(
        address user,
        address[] memory tokens
    ) public view returns (BasePoolInfo[] memory poolInfo) {
        uint256 poolInfoCount = getUserPoolIDs(user).length;
        poolInfo = new BasePoolInfo[](poolInfoCount);
        for(uint256 i = 0; i < tokens.length; ++i){
            uint256[] memory poolIds = getUserPoolIDsByToken(user, tokens[i]);
            for(uint256 j = 0; j < poolIds.length; ++j){
                poolInfo[j] = getData(poolIds[j]);
            }
        }
    }

    function getDataByPoolIDs(
        uint256[] memory poolIds
    ) public view returns (BasePoolInfo[] memory poolInfo) {
        uint256 poolCount = poolIds.length;
        poolInfo = new BasePoolInfo[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            poolInfo[i] = getData(poolIds[i]);
        }
    }

    function getUserPoolIDs(
        address user
    ) public view returns (uint256[] memory poolIds) {
        uint256 poolCount = balanceOf(user);
        poolIds = new uint256[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            poolIds[i] = tokenOfOwnerByIndex(user, i);
        }
    }

    function getUserPoolIDsByToken(
        address user,
        address token
    ) public view returns (uint256[] memory poolIds) {
        uint256 poolCount = balanceOf(user);
        poolIds = new uint256[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            uint256 poolId = tokenOfOwnerByIndex(user, i);
            if (tokenOf(poolId) == token) {
                poolIds[i] = poolId;
            }
        }
    }

    function getAllPoolIdsByToken(address token) public view returns(uint256 [] memory poolIds) {
        uint256 poolCount = totalSupply();
        poolIds = new uint256[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            uint256 poolId = tokenByIndex(i);
            if (tokenOf(poolId) == token) {
                poolIds[i] = poolId;
            }
        }
    }

    function tokenOf(uint256 poolId) public view returns (address token) {
        token = vaultManager.vaultIdToTokenAddress(poolIdToVaultId[poolId]);
    }

    /// @dev Checks if a pool with the given ID exists
    /// @param poolId The ID of the pool
    /// @return boolean indicating whether the pool exists or not
    function exist(uint256 poolId) external view returns (bool) {
        return _exists(poolId);
    }

    function getWithdrawableAmount(uint256 poolId) external view returns(uint256 withdrawalAmount) {
        if (_exists(poolId)) {
            withdrawalAmount = poolIdToProvider[poolId].getWithdrawableAmount(poolId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(keccak256(abi.encodePacked(baseURI)) != keccak256(abi.encodePacked(newBaseURI)), "can't set the same baseURI");
        string memory oldBaseURI = baseURI;
        baseURI = newBaseURI;
        emit BaseURIChanged(oldBaseURI, newBaseURI);
    }
}
