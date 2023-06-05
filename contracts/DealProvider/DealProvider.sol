// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./DealProviderModifiers.sol";

contract DealProvider is DealProviderModifiers {
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
    }

    ///@param params[0] = amount
    ///@dev requirements are in mint, _register functions
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);
        _registerPool(poolId, owner, token, params);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, poolIdToDeal[poolId].leftAmount);
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, amount);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolIdToDeal[poolId].leftAmount >= amount) {
            poolIdToDeal[poolId].leftAmount -= amount;
            withdrawnAmount = amount;
            isFinal = poolIdToDeal[poolId].leftAmount == 0;
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
        onlyProvider
        invalidSplitAmount(poolIdToDeal[oldPoolId].leftAmount, splitAmount)
    {
        poolIdToDeal[oldPoolId].leftAmount -= splitAmount;
        poolIdToDeal[newPoolId].leftAmount = splitAmount;
        poolIdToDeal[newPoolId].token = poolIdToDeal[oldPoolId].token;
        emit PoolSplit(
            oldPoolId,
            lockDealNFT.ownerOf(oldPoolId),
            newPoolId,
            lockDealNFT.ownerOf(newPoolId),
            poolIdToDeal[oldPoolId].leftAmount,
            poolIdToDeal[newPoolId].leftAmount
        );
    }
}
