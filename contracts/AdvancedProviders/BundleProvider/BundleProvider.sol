// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BundleModifiers.sol";
import "../../util/CalcUtils.sol";
import "../../interfaces/ISimpleProvider.sol";
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

    ///@param addresses[0] = owner
    ///@param addresses[1] = token
    ///@param addresses[>= 2] = providers
    ///@param providerParams[][0] = leftAmount
    ///@param providerParams[][1] = startTime
    ///@param providerParams[][2] = finishTime
    ///@param providerParams[][3] = startAmount
    function createNewPool(
        address[] calldata addresses,
        uint256[][] calldata providerParams
    ) external validAddressesLength(addresses.length, 4) returns (uint256 poolId) {
        uint256 providerCount = addresses.length - 2;
        require(providerCount == providerParams.length, "providers and params length mismatch");
        uint256 totalAmount = _calcTotalAmount(providerParams);
        // create a new bundle pool owned by the owner

        poolId = lockDealNFT.mintAndTransfer(addresses[0], addresses[1], msg.sender, totalAmount, this);
        uint256[] memory registerParams = new uint256[](1);
        registerParams[0] = poolId + providerCount;
        for (uint256 i; i < providerCount; ++i) {
            address provider = addresses[i + 2];
            uint256[] memory params = providerParams[i];
            // mint the NFT owned by the BunderDealProvider with 0 token transfer amount
            _createNewSubPool(provider, params);
        }
        _registerPool(poolId, registerParams);
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    )
        external
        override
        validBundleParams(poolId, params[0])
        onlyProvider
        validParamsLength(params.length, currentParamsTargetLenght())
    {
        _registerPool(poolId, params);
    }

    ///@param params[0] = lastSubPoolId
    function _registerPool(uint256 poolId, uint256[] memory params) internal validLastPoolId(poolId, params[0]) {
        bundlePoolIdToLastSubPoolId[poolId] = params[0];
        emit UpdateParams(poolId, params);
    }

    function _createNewSubPool(
        address provider,
        uint256[] memory params
    ) internal validProviderInterface(IProvider(provider), Bundable._INTERFACE_ID_BUNDABLE) {
        _createNewSubPool(IProvider(provider), params);
    }

    function _createNewSubPool(IProvider provider, uint256[] memory params) internal {
        provider.registerPool(lockDealNFT.mintForProvider(address(this), provider), params);
    }

    function withdraw(uint256 poolId) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        // withdraw the sub pools
        uint256 lastSubPoolId = bundlePoolIdToLastSubPoolId[poolId];
        isFinal = true;
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            address provider = address(lockDealNFT.poolIdToProvider(i));
            uint256 amount = lockDealNFT.getWithdrawableAmount(i);
            (uint256 subPoolWithdrawnAmount, bool subPoolIsFinal) = ISimpleProvider(provider).withdraw(i, amount);
            withdrawnAmount += subPoolWithdrawnAmount;
            isFinal = isFinal && subPoolIsFinal;
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
        params = new uint256[](currentParamsTargetLenght() + 1);
        params[0] = getTotalRemainingAmount(poolId);
        params[1] = bundlePoolIdToLastSubPoolId[poolId];
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
