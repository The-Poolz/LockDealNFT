// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderModifiers.sol";
import "../Provider/BasicProvider.sol";

contract DealProvider is DealProviderModifiers, BasicProvider {
    constructor(ILockDealNFT _nftContract) {
        require(address(_nftContract) != address(0x0), "invalid address");
        lockDealNFT = _nftContract;
        name = "DealProvider";
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolIdToAmount[poolId] >= amount) {
            poolIdToAmount[poolId] -= amount;
            withdrawnAmount = amount;
            isFinal = poolIdToAmount[poolId] == 0;
            emit TokenWithdrawn(
                poolId,
                lockDealNFT.ownerOf(poolId),
                withdrawnAmount,
                poolIdToAmount[poolId]
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
        invalidSplitAmount(poolIdToAmount[oldPoolId], splitAmount)
    {
        poolIdToAmount[oldPoolId] -= splitAmount;
        poolIdToAmount[newPoolId] = splitAmount;
        emit PoolSplit(
            oldPoolId,
            lockDealNFT.ownerOf(oldPoolId),
            newPoolId,
            lockDealNFT.ownerOf(newPoolId),
            poolIdToAmount[oldPoolId],
            poolIdToAmount[newPoolId]
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
        poolIdToAmount[poolId] = params[0];
        address owner = lockDealNFT.ownerOf(poolId);
        address token = lockDealNFT.tokenOf(poolId);
        emit NewPoolCreated(poolId, owner, token, params);
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        uint256 leftAmount = poolIdToAmount[poolId];
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return poolIdToAmount[poolId];
    }
}
