// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealBundleProviderState.sol";
import "../Provider/ProviderModifiers.sol";
import "../ProviderInterface/IProvider.sol";
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
        uint256 providerCount = providers.length;
        require(providerCount == providerParams.length, "providers and params length mismatch");
        require(providerCount > 1, "providers length must be greater than 1");

        uint256 totalAmount = _calcTotalAmount(providerParams);
        // create a new bundle pool owned by the owner
        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, totalAmount, address(this));

        uint256 lastSubPoolId;
        for (uint256 i; i < providerCount; ++i) {
            address provider = providers[i];
            uint256[] memory params = providerParams[i];

            // check if the provider address is valid
            require(provider != address(lockDealNFT) && provider != address(this), "invalid provider address");
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            lastSubPoolId = _createNewSubPool(address(this), provider, params);
        }

        bundlePoolIdToLastSubPoolId[poolId] = lastSubPoolId;
    }

    function registerPool(uint256 poolId,uint256[] calldata params) external override onlyNFT {
        // will be implemented in the future
    }

    function _createNewSubPool(
        address owner,
        address provider,
        uint256[] memory params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, provider);
        IProvider(provider).registerPool(poolId, params);
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // withdraw the sub pools
        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        isFinal = true;
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            // if the sub pool was already withdrawn and burnt, skip it
            if (lockDealNFT.exist(i)) {
                (uint256 subPoolWithdrawnAmount, bool subPoolIsFinal) = lockDealNFT.withdraw(i);
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
        uint256 oldLastSubPoolId = bundlePoolIdToLastSubPoolId[oldPoolId];
        for (uint256 i = oldPoolId + 1; i <= oldLastSubPoolId; ++i) {
            (,, uint256[] memory params) = lockDealNFT.getData(i);
            uint256 oldSubPoolRemainingAmount = params[0];  // leftAmount
            uint256 subPoolSplitAmount = _calcAmount(oldSubPoolRemainingAmount, rate);

            // split the sub poold
            lockDealNFT.split(i, subPoolSplitAmount, address(this));
        }

        // finally, set the bundle provider state with the last sub pool Id
        bundlePoolIdToLastSubPoolId[newPoolId] = oldLastSubPoolId + (newPoolId - oldPoolId);
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = bundlePoolIdToLastSubPoolId[poolId]; //TODO this will change to the Last Pool Id
    }

    function getTotalRemainingAmount(uint256 poolId) public view returns (uint256 totalRemainingAmount) {
        (address provider,,) = lockDealNFT.getData(poolId);
        require(provider == address(this), "not bundle poolId");

        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            (,, uint256[] memory params) = lockDealNFT.getData(i);
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
