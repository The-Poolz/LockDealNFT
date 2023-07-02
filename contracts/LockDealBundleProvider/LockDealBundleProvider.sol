// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderState.sol";
import "../Provider/ProviderModifiers.sol";
import "../ProviderInterface/IProvider.sol";
import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract LockDealBundleProvider is
    LockDealBundleProviderState,
    ProviderModifiers,
    IProvider,
    ERC721Holder
{
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

        uint256[] memory subPoolIds = new uint256[](providerCount);
        uint256 totalStartAmount;
        for (uint256 i; i < providerCount; ++i) {
            address provider = providers[i];
            uint256[] memory params = providerParams[i];

            // check if the provider address is valid
            require(provider != address(lockDealNFT) && provider != address(this), "invalid provider address");

            // create the pool and store the first sub poolId
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            uint256 subPoolId = _createNewSubPool(address(this), provider, params);
            subPoolIds[i] = subPoolId;

            // increase the `totalStartAmount`
            totalStartAmount += params[0];
        }

        // create a new bundle pool owned by the owner with `totalStartAmount` token trasnfer amount
        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, totalStartAmount, address(this));
        bundlePoolIdToSubPoolIds[poolId] = subPoolIds;
    }

    function _createNewSubPool(
        address owner,
        address provider,
        uint256[] memory params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, provider);
        IProviderSingleIdRegistrar(provider).registerPool(poolId, params);
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // withdraw the sub pools
        uint256[] memory subPoolIds = bundlePoolIdToSubPoolIds[poolId];
        isFinal = true;
        for (uint256 i; i < subPoolIds.length; ++i) {
            uint256 subPool = subPoolIds[i];
            // if the sub pool was already withdrawn and burnt, skip it
            if (lockDealNFT.exist(subPool)) {
                (uint256 subPoolWithdrawnAmount, bool subPoolIsFinal) = lockDealNFT.withdraw(subPool);
                withdrawnAmount += subPoolWithdrawnAmount;
                isFinal = isFinal && subPoolIsFinal;
            }
        }
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyProvider {
        uint256 oldPoolTotalRemainingAmount = getTotalRemainingAmount(oldPoolId);
        uint256 rate = _calcRate(oldPoolTotalRemainingAmount, splitAmount);
        require(rate > 1e18, "split amount exceeded");

        // split the sub pools
        uint256[] memory oldSubPoolIds = bundlePoolIdToSubPoolIds[oldPoolId];
        uint256 oldSubPoolCount = oldSubPoolIds.length;
        uint256[] memory newSubPoolIds = new uint256[](oldSubPoolCount);
        for (uint256 i; i < oldSubPoolCount; ++i) {
            uint256 oldSubPoolId = oldSubPoolIds[i];
            (,, uint256[] memory params) = lockDealNFT.getData(oldSubPoolId);
            uint256 oldSubPoolRemainingAmount = params[0];  // leftAmount
            uint256 subPoolSplitAmount = _calcAmount(oldSubPoolRemainingAmount, rate);

            lockDealNFT.split(oldSubPoolId, subPoolSplitAmount, address(this));
            newSubPoolIds[i] = newPoolId + i + 1;
        }

        // set the sub pools of thew new bundle pool
        bundlePoolIdToSubPoolIds[newPoolId] = newSubPoolIds;
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = bundlePoolIdToSubPoolIds[poolId]; //TODO this will change to the Last Pool Id
    }

    function getTotalRemainingAmount(uint256 poolId) public view returns (uint256 totalRemainingAmount) {
        (address provider,,) = lockDealNFT.getData(poolId);
        require(provider == address(this), "not bundle poolId");

        uint256[] memory subPoolIds = bundlePoolIdToSubPoolIds[poolId];
        for (uint256 i; i < subPoolIds.length; ++i) {
            uint256 subPoolId = subPoolIds[i];
            (,, uint256[] memory params) = lockDealNFT.getData(subPoolId);
            totalRemainingAmount += params[0];  // leftAmount
        }
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return (tokenAValue * 1e18) / tokenBValue;
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return amount * 1e18 / rate;
    }
}
