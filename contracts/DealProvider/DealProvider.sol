// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./DealProviderModifiers.sol";
import "../ProviderInterface/ISplitble.sol";

contract DealProvider is DealProviderModifiers, ISplitble {
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
    }

    /**
     * @dev used by LockedDealNFT contract to withdraw tokens from a pool.
     * @param poolId The ID of the pool.
     * @return withdrawnAmount The amount of tokens withdrawn.
     * @return isFinal Boolean indicating whether the pool is empty after a withdrawal.
     */
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, poolIdToleftAmount[poolId]);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolIdToleftAmount[poolId] >= amount) {
            poolIdToleftAmount[poolId] -= amount;
            withdrawnAmount = amount;
            isFinal = poolIdToleftAmount[poolId] == 0;
            emit TokenWithdrawn(
                poolId,
                lockDealNFT.ownerOf(poolId),
                withdrawnAmount,
                poolIdToleftAmount[poolId]
            );
        }
    }
    
    /// @dev Splits a pool into two pools. Used by the LockedDealNFT contract or Provider
    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    )
        public
        override
        onlyProvider
        invalidSplitAmount(poolIdToleftAmount[oldPoolId], splitAmount)
    {
        poolIdToleftAmount[oldPoolId] -= splitAmount;
        poolIdToleftAmount[newPoolId] = splitAmount;
        emit PoolSplit(
            oldPoolId,
            lockDealNFT.ownerOf(oldPoolId),
            newPoolId,
            lockDealNFT.ownerOf(newPoolId),
            poolIdToleftAmount[oldPoolId],
            poolIdToleftAmount[newPoolId]
        );
    }

    /**@dev Providers overrides this function to add additional parameters when creating a pool.
     * @param poolId The ID of the pool.
     * @param params An array of additional parameters.
     */
    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal override {
        poolIdToleftAmount[poolId] = params[0];
        address owner = lockDealNFT.ownerOf(poolId);
        address token = lockDealNFT.tokenOf(poolId);
        emit NewPoolCreated(poolId, owner, token, params);
    }

    function getData(uint256 poolId) external view override returns (BasePoolInfo memory poolInfo, uint256[] memory params) {
        address token = lockDealNFT.tokenOf(poolId);
        uint256 leftAmount = poolIdToleftAmount[poolId];
        address owner = lockDealNFT.exist(poolId) ? lockDealNFT.ownerOf(poolId) : address(0);
        poolInfo = BasePoolInfo(poolId, owner, token);
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }
}
