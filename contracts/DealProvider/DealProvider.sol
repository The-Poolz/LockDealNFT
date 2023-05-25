// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./DealProviderModifiers.sol";
import "../interface/IProvider.sol";

contract DealProvider is DealProviderModifiers, IProvider {
    constructor(address _nftContract) {
        lockDealNFT = LockDealNFT(_nftContract);
    }

    /// params[0] = amount
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    )
        public
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(params[0])
        validParamsLength(params.length, currentParamsTargetLenght)
        returns (uint256 poolId)
    {
        poolId = lockDealNFT.mint(owner, token);
        poolIdToDeal[poolId].leftAmount = params[0];
        poolIdToDeal[poolId].token = token;
        emit NewPoolCreated(BasePoolInfo(poolId, owner, token), params);
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        if (msg.sender == address(lockDealNFT)) {
            withdrawnAmount = _withdraw(
                poolId,
                poolIdToDeal[poolId].leftAmount
            );
        }
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public returns (uint256 withdrawnAmount) {
        if (lockDealNFT.approvedProviders(msg.sender)) {
            withdrawnAmount = _withdraw(poolId, amount);
        }
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal returns (uint256 withdrawnAmount) {
        if (poolIdToDeal[poolId].leftAmount >= amount) {
            poolIdToDeal[poolId].leftAmount -= amount;
            withdrawnAmount = amount;
            emit TokenWithdrawn(
                poolId,
                lockDealNFT.ownerOf(poolId),
                withdrawnAmount,
                poolIdToDeal[poolId].leftAmount
            );
        }
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    )
        public
        override
        notZeroAmount(splitAmount)
        onlyProvider
        invalidSplitAmount(poolIdToDeal[oldPoolId].leftAmount, splitAmount)
    {
        poolIdToDeal[oldPoolId].leftAmount -= splitAmount;
        poolIdToDeal[newPoolId].leftAmount = splitAmount;
        emit PoolSplit(
            oldPoolId,
            lockDealNFT.ownerOf(oldPoolId),
            newPoolId,
            lockDealNFT.ownerOf(newPoolId),
            poolIdToDeal[oldPoolId].leftAmount,
            poolIdToDeal[newPoolId].leftAmount
        );
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        public
        onlyProvider
        validParamsLength(params.length, currentParamsTargetLenght)
    {
        poolIdToDeal[poolId].leftAmount = params[0];
    }
}
