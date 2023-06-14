// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderModifiers.sol";
import "../Provider/ProviderModifiers.sol";
import "../ProviderInterface/IProvider.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IProviderExtend {
    function createNewPool(address owner, address token, uint256[] memory params) external returns (uint256 poolId);
}

contract LockDealBundleProvider is
    ProviderModifiers,
    LockDealBundleProviderModifiers,
    IProvider,
    ERC721Holder
{
    using SafeERC20 for IERC20;

    constructor(address nft) {
        require(
            nft != address(0x0),
            "invalid address"
        );
        lockDealNFT = LockDealNFT(nft);
    }

    ///@param providerParams[][0] = leftAmount
    ///@param providerParams[][1] = startTime
    ///@param providerParams[][2] = finishTime
    ///@param providerParams[][3] = startAmount
    function createNewPool(
        address owner,
        address token,
        address[] calldata providers,
        uint256[][] calldata providerParams
    ) external returns (uint256 poolId) {
        // amount for LockDealProvider = `totalAmount` - `startAmount`
        // amount for TimedDealProvider = `startAmount`

        // mint the NFT owned by the BunderDealProvider on LockDealProvider for `totalAmount` - `startAmount` token amount
        // mint the NFT owned by the BunderDealProvider on TimedDealProvider for `startAmount` token amount
        // mint the NFT owned by the owner on LockDealBundleProvider for `totalAmount` token transfer amount

        // To optimize the token transfer (for 1 token transfer)
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on LockDealProvider
        // mint the NFT owned by the BunderDealProvider with 0 token transfer amount on TimedDealProvider
        // mint the NFT owned by the owner with `totalAmount` token transfer amount on LockDealBundleProvider

        uint256 providerCount = providers.length;
        require(providerCount == providerParams.length, "providers and params length mismatch");
        require(providerCount > 1, "providers length must be greater than 1");

        uint256 firstSubPoolId;
        for (uint256 i; i < providerCount; ++i) {
            address provider = providers[i];
            uint256[] memory params = providerParams[i];

            // check if the provider address is valid
            require(
                lockDealNFT.approvedProviders(provider) &&
                provider != address(lockDealNFT),
                "invalid provider address"
            );

            // create the pool and store the first sub poolId
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            uint256 subPoolId = _createNewSubPool(address(this), token, msg.sender, params, provider);
            if (i == 0) firstSubPoolId = subPoolId;
        }

        // create a new pool owned by the owner with 0 token trasnfer amount
        poolId = lockDealNFT.mint(owner, token, msg.sender, 0);
        poolIdToLockDealBundle[poolId].firstSubPoolId = firstSubPoolId;
        isLockDealBundlePoolId[poolId] = true;
    }

    function _createNewSubPool(
        address owner,
        address token,
        address from,
        uint256[] memory params,
        address provider
    ) internal returns (uint256 poolId) {
        IERC20(token).safeTransferFrom(from, address(this), params[0]);
        IERC20(token).safeIncreaseAllowance(address(lockDealNFT.vaultManager()), params[0]);
        poolId = IProviderExtend(provider).createNewPool(owner, token, params);
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT onlyBundlePoolId(poolId) returns (uint256 withdrawnAmount, bool isFinal) {
        // withdraw the sub pools
        uint256 firstSubPoolId = poolIdToLockDealBundle[poolId].firstSubPoolId;
        isFinal = true;
        for (uint256 i = firstSubPoolId; i < poolId; ++i) {
            // if the sub pool was already withdrawn and burnt, skip it
            if (lockDealNFT.exist(i)) {
                (uint256 subPoolWithdrawnAmount, bool subPoolIsFinal) = lockDealNFT.withdraw(i);
                withdrawnAmount += subPoolWithdrawnAmount;
                isFinal = isFinal && subPoolIsFinal;
            }
        }

        // transfer the payment token to the owner
        address firstSubPoolProvider = lockDealNFT.poolIdToProvider(firstSubPoolId);
        (IDealProvierEvents.BasePoolInfo memory firstSubPoolInfolInfo, ) = IProvider(firstSubPoolProvider).getData(firstSubPoolId);
        address token = firstSubPoolInfolInfo.token;
        address owner = lockDealNFT.ownerOf(poolId);
        IERC20(token).safeTransfer(owner, withdrawnAmount);
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public onlyProvider {
    }

    function getData(uint256 poolId) public view override onlyBundlePoolId(poolId) returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        address owner = lockDealNFT.ownerOf(poolId);
        poolInfo = IDealProvierEvents.BasePoolInfo(poolId, owner, address(0));
        params = new uint256[](1);
        params[0] = poolIdToLockDealBundle[poolId].firstSubPoolId; // firstSubPoolId
    }
}
