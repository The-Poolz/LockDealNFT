// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../Provider/IProvierEvents.sol";
import "../Provider/ProviderModifiers.sol";

abstract contract Provider is
    ProviderModifiers,
    IProvierEvents
{
    constructor(address nftContract) {
        NftContract = LockDealNFT(nftContract);
    }

    LockDealNFT public NftContract;

    function _onlyOwnerOrAdmin(uint256 itemId) private view {
        require(
            msg.sender == NftContract.ownerOf(itemId) ||
                msg.sender == NftContract.owner(),
            "Not the owner of the pool"
        );
    }

    modifier onlyOwnerOrAdmin(uint256 itemId) {
        _onlyOwnerOrAdmin(itemId);
        _;
    }

    function withdraw(
        uint256 itemId
    ) external virtual returns (uint256 withdrawnAmount);

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external virtual;

    function createBasePoolInfo(
        uint256 poolId,
        address owner,
        address token
    ) internal pure returns (BasePoolInfo memory poolInfo) {
        poolInfo.PoolId = poolId;
        poolInfo.Owner = owner;
        poolInfo.Token = token;
    }

    function mint(address to) internal returns (uint256 poolId)
    {
        poolId = NftContract.totalSupply();
        NftContract.mint(to);
    }
}
