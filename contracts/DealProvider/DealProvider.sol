// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./DealProviderModifiers.sol";
import "./IDealProvierEvents.sol";

abstract contract DealProvider is
    IDealProvierEvents,
    DealProviderModifiers,
    ERC20Helper
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function withdraw(
        uint256 poolId,
        uint256 withdrawnAmount
    ) public onlyApprovedProvider(msg.sender) {
        if (withdrawnAmount > 0 && providers[msg.sender]) {
            poolIdToDeal[poolId].startAmount -= withdrawnAmount;
            TransferToken(
                poolIdToDeal[poolId].token,
                nftContract.ownerOf(poolId),
                withdrawnAmount
            );
        }
    }

    function createNewPool(
        address owner,
        address token,
        uint256 amount
    ) public onlyApprovedProvider(msg.sender) returns (uint256 newPoolId) {
        newPoolId = nftContract.totalSupply();
        poolIdToDeal[newPoolId] = Deal(token, amount);
        nftContract.mint(owner);
    }

    function split(
        uint256 poolId,
        uint256 splitAmount
    ) public onlyApprovedProvider(msg.sender) {
        poolIdToDeal[poolId].startAmount -= splitAmount;
    }

    function getDeal(uint256 poolId) public view returns (address, uint256) {
        return (poolIdToDeal[poolId].token, poolIdToDeal[poolId].startAmount);
    }

    function createBasePoolInfo(
        uint256 poolId,
        address owner,
        address token
    ) internal pure returns (IDealProvierEvents.BasePoolInfo memory poolInfo) {
        poolInfo.PoolId = poolId;
        poolInfo.Owner = owner;
        poolInfo.Token = token;
    }
}
