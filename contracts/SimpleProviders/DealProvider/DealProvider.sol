// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderState.sol";
import "../Provider/BasicProvider.sol";
import "@poolzfinance/poolz-helper-v2/contracts/CalcUtils.sol";

contract DealProvider is DealProviderState, BasicProvider {
    using CalcUtils for uint256;

    constructor(ILockDealNFT _nftContract) {
        require(address(_nftContract) != address(0x0), "invalid address");
        lockDealNFT = _nftContract;
        name = "DealProvider";
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override firewallProtectedSig(0x9e2bf22c) returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolIdToAmount[poolId] >= amount) {
            poolIdToAmount[poolId] -= amount;
            withdrawnAmount = amount;
            isFinal = poolIdToAmount[poolId] == 0;
        }
    }

    /// @dev Splits a pool into two pools. Used by the LockedDealNFT contract or Provider
    function split(uint256 lockDealNFTPoolId, uint256 newPoolId, uint256 ratio) external override firewallProtected onlyProvider {
        uint256 splitAmount = poolIdToAmount[lockDealNFTPoolId].calcAmount(ratio);
        require(poolIdToAmount[lockDealNFTPoolId] >= splitAmount, "Split amount exceeds the available amount");
        poolIdToAmount[newPoolId] = splitAmount;
        // save leftAmount to the newly created pool from the old pool
        uint256 copyOldPoolId = _mintNewNFT(lockDealNFTPoolId, lockDealNFT.ownerOf(newPoolId));
        poolIdToAmount[copyOldPoolId] = poolIdToAmount[lockDealNFTPoolId] - splitAmount;
        // set to 0 to finalize the pool
        poolIdToAmount[lockDealNFTPoolId] = 0;
    }

    /**@dev Providers overrides this function to add additional parameters when creating a pool.
     * @param poolId The ID of the pool.
     * @param params An array of additional parameters.
     */
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override firewallProtectedSig(0x677df66b) {
        poolIdToAmount[poolId] = params[0];
        emit UpdateParams(poolId, params);
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        uint256 leftAmount = poolIdToAmount[poolId];
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return poolIdToAmount[poolId];
    }

    /// @dev creates a new NFT and clones the vault id from the source pool id.
    /// @param sourcePoolId The ID of the source pool.
    /// @param to The address of the NFT owner.
    /// @return newPoolId The ID of the newly created pool.
    /// 0x21de57c4 - represents bytes4(keccak256("_mintNewNFT(uint256,address)"))
    function _mintNewNFT(
        uint256 sourcePoolId,
        address to
    ) internal firewallProtectedSig(0x21de57c4) returns (uint256 newPoolId) {
        IProvider sourceProvider = lockDealNFT.poolIdToProvider(sourcePoolId);
        newPoolId = lockDealNFT.mintForProvider(to, sourceProvider);
        // clone vault id
        lockDealNFT.cloneVaultId(newPoolId, sourcePoolId);
    }
}
