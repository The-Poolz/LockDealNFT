// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BundleModifiers.sol";
import "../../util/CalcUtils.sol";
import "../../SimpleProviders/Provider/BasicProvider.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../../ERC165/Bundable.sol";

contract BundleProvider is BundleModifiers, ERC721Holder {
    using CalcUtils for uint256;

    constructor(ILockDealNFT _lockDealNFT) {
        require(address(_lockDealNFT) != address(0x0), "invalid address");
        lockDealNFT = _lockDealNFT;
        name = "BundleProvider";
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

        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, totalAmount, this);
        uint256 lastSubPoolId;
        for (uint256 i; i < providerCount; ++i) {
            address provider = providers[i];
            uint256[] memory params = providerParams[i];

            // check if the provider address is valid
            require(provider != address(lockDealNFT) && provider != address(this), "invalid provider address");
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            lastSubPoolId = _createNewSubPool(address(this), IProvider(provider), params);
        }
        uint256[] memory registerParams = new uint256[](1);
        registerParams[0] = lastSubPoolId;
        _registerPool(poolId, registerParams);
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) external override onlyProvider validParamsLength(params.length, currentParamsTargetLenght()) {
        _registerPool(poolId, params);
    }

    ///@param params[0] = lastSubPoolId
    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal validBundleParams(poolId, params[0]) validLastPoolId(poolId, params[0]) {
        bundlePoolIdToLastSubPoolId[poolId] = params[0];
        emit UpdateParams(poolId, params);
    }

    function _createNewSubPool(
        address owner,
        IProvider provider,
        uint256[] memory params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, provider);
        provider.registerPool(poolId, params);
    }

    function withdraw(uint256 poolId) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // withdraw the sub pools
        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        isFinal = true;
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            if (lockDealNFT.exist(i)) {
                address provider = address(lockDealNFT.poolIdToProvider(i));
                uint256 amount = lockDealNFT.getWithdrawableAmount(i);
                (uint256 subPoolWithdrawnAmount, bool subPoolIsFinal) = BasicProvider(provider).withdraw(i, amount);
                withdrawnAmount += subPoolWithdrawnAmount;
                isFinal = isFinal && subPoolIsFinal;
            }
        }
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) public override onlyProvider {
        uint256 oldLastSubPoolId = bundlePoolIdToLastSubPoolId[oldPoolId];
        for (uint256 i = oldPoolId + 1; i <= oldLastSubPoolId; ++i) {
            // split the sub poold
            lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), i, abi.encode(ratio));
        }
        // finally, set the bundle provider state with the last sub pool Id
        bundlePoolIdToLastSubPoolId[newPoolId] = oldLastSubPoolId + (newPoolId - oldPoolId);
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = bundlePoolIdToLastSubPoolId[poolId]; //TODO this will change to the Last Pool Id
    }

    function getTotalRemainingAmount(
        uint256 poolId
    ) public view validProviderId(poolId) returns (uint256 totalRemainingAmount) {
        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            totalRemainingAmount += lockDealNFT.getData(i).params[0]; // leftAmount
        }
    }
}
