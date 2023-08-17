// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiWithdrawState.sol";

contract MultiWithdrawProvider is MultiWithdrawState {
    constructor(ILockDealNFT nftContract, uint256 _maxPoolsPerTx) {
        name = "MultiWithdrawProvider";
        lockDealNFT = nftContract;
        maxPoolsPerTx = _maxPoolsPerTx;
    }

    function multiWithdrawAllPoolsOfOwner(address _owner)
        external
        onlyAdminOrNftOwner(_owner) 
    {
        uint256[] memory poolIds = getAllPoolsOfOwner(_owner);
        _processMultiWithdraw(poolIds, _owner);
    }

    function multiWithdrawPoolsOfOwnerByVault(address _owner, uint256 _vaultId)
        external
        onlyAdminOrNftOwner(_owner)
    {
        uint256[] memory poolIds = getPoolsOfOwnerByVault(_owner, _vaultId);
        _processMultiWithdraw(poolIds, _owner);
    }

    function multiWithdrawPools(uint256[] memory _poolIds) external onlyOwner {
        _processMultiWithdraw(_poolIds);
    }

    function getAllPoolsOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 totalPools = lockDealNFT.balanceOf(_owner);
        uint256[] memory poolIds = new uint256[](totalPools);
        for(uint256 i = 0; i < totalPools; ) {
            poolIds[i] = lockDealNFT.tokenOfOwnerByIndex(_owner, i);
            unchecked { ++i; }
        }
        return poolIds;
    }

    function getPoolsOfOwnerByVault(address _owner, uint256 _vaultId) public view returns (uint256[] memory) {
        uint256 totalPools = lockDealNFT.balanceOf(_owner);
        uint256[] memory poolIds = new uint256[](totalPools);
        uint256 index;
        for(uint256 i = 0; i < totalPools; ) {
            uint256 poolId = lockDealNFT.tokenOfOwnerByIndex(_owner, i);
            if (lockDealNFT.getData(poolId).vaultId == _vaultId) {
                poolIds[index] = poolId;
                unchecked { ++index; }
            }
            unchecked { ++i; }
        }
        return poolIds;
    }

    /// @param _poolIds Array of pool ids to withdraw
    function _processMultiWithdraw(uint256[] memory _poolIds) private {
        require(_poolIds.length <= maxPoolsPerTx, "Too many pools");
        for(uint256 i = 0; i < _poolIds.length; i++) {
            lockDealNFT.transferFrom(lockDealNFT.ownerOf(_poolIds[i]), address(lockDealNFT), _poolIds[i]);
        }
    }

    /// @dev should be used only when the owner is the same for all pools
    /// @param _poolIds Array of pool ids to withdraw
    /// @param _owner must be the owner of all _poolIds
    function _processMultiWithdraw(uint256[] memory _poolIds, address _owner) private {
        require(_poolIds.length <= maxPoolsPerTx, "Too many pools");
        for(uint256 i = 0; i < _poolIds.length; i++) {
            lockDealNFT.transferFrom(_owner, address(lockDealNFT), _poolIds[i]);
        }
    }
}