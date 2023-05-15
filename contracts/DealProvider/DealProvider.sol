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
        address owner,
        address token,
        uint256[] memory params
    ) internal virtual validParams(params, 2) returns (uint256 newItemId) {
        newItemId = nftContract.totalSupply();
        itemIdToDeal[newItemId] = Deal(token, params[0], params[1]);
        nftContract.mint(owner);
    }

    function GetParams(
        uint256 amount,
        uint256 startTime
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = amount;
        params[1] = startTime;
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
