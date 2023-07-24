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

    function getData(uint256 poolId)
        public
        view
        returns (
            IProvider provider,
            BasePoolInfo memory poolInfo,
            uint256[] memory params
        )
    {
        if (_exists(poolId)) {
            provider = poolIdToProvider[poolId];
            params = provider.getParams(poolId);
            poolInfo = BasePoolInfo(poolId, ownerOf(poolId), tokenOf(poolId));
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
        baseURI = newBaseURI;
    }
}
