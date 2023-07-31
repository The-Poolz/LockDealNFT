// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderModifiers.sol";
import "../Provider/BasicProvider.sol";

contract DealProvider is DealProviderModifiers, BasicProvider {
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
        name = "DealProvider";
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
        uint256[] calldata params
    ) internal override {
        poolIdToleftAmount[poolId] = params[0];
        address owner = lockDealNFT.ownerOf(poolId);
        address token = lockDealNFT.tokenOf(poolId);
        emit NewPoolCreated(poolId, owner, token, params);
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        uint256 leftAmount = poolIdToleftAmount[poolId];
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return poolIdToleftAmount[poolId];
    }
}
