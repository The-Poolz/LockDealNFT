// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./DealProviderModifiers.sol";
import "../interface/IProvider.sol";

contract DealProvider is DealProviderModifiers, IProvider {
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
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
        validParamsLength(params.length, currentParamsTargetLenght)
        returns (uint256 poolId)
    {
        _registerPool(poolId, token, params);
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);
        emit NewPoolCreated(BasePoolInfo(poolId, owner, token), params);
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount) {
        withdrawnAmount = withdraw(poolId, poolIdToDeal[poolId].leftAmount);
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public returns (uint256 withdrawnAmount) {
        if (
            poolIdToDeal[poolId].leftAmount >= amount &&
            lockDealNFT.approvedProviders(msg.sender)
        ) {
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
        address token,
        uint256[] memory params
    ) public onlyProvider {
        _registerPool(poolId, token, params);
    }

    function _registerPool(
        uint256 poolId,
        address token,
        uint256[] memory params
    )
        internal
        notZeroAmount(params[0])
        validParamsLength(params.length, currentParamsTargetLenght)
    {
        poolIdToDeal[poolId].leftAmount = params[0];
        poolIdToDeal[poolId].token = token;
    }
}
