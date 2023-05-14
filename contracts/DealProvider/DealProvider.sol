// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../interface/ICustomLockedDeal.sol";
import "./DealProviderModifiers.sol";
import "./IDealProvierEvents.sol";

abstract contract DealProvider is
    ICustomLockedDeal,
    IDealProvierEvents,
    DealProviderModifiers,
    ERC20Helper
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function withdraw(
        uint256 itemId
    ) external virtual returns (uint256 withdrawnAmount);

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external virtual;

    function _createNewPool(
        address token,
        uint256 amount,
        uint256 startTime,
        address owner
    ) internal virtual returns (uint256 newItemId) {
        nftContract.mint(owner);
        newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(token, amount, startTime);
    }

    function createBasePoolInfo(
        uint256 poolId,
        address owner,
        address token
    ) internal pure returns (IDealProvierEvents.BasePoolInfo memory) {
        IDealProvierEvents.BasePoolInfo memory poolInfo;
        poolInfo.PoolId = poolId;
        poolInfo.Owner = owner;
        poolInfo.Token = token;
        return poolInfo;
    }

    function _withdraw(
        uint256 itemId,
        uint256 withdrawnAmount
    ) internal virtual {
        TransferToken(
            itemIdToDeal[itemId].token,
            nftContract.ownerOf(itemId),
            withdrawnAmount
        );
    }
}
