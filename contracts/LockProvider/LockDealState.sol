// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../DealProvider/DealProvider.sol";
import "../Provider/ProviderModifiers.sol";
import "../interface/IProvider.sol";

/// @title LockDealState contract
/// @notice Contains storage variables
abstract contract LockDealState is IProvider, ProviderModifiers {
    DealProvider public dealProvider;
    mapping(uint256 => uint256) public startTimes;
    uint256 public constant currentParamsTargetLenght = 1;

    function registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) public onlyProvider {
        _registerPool(poolId, owner, token, params);
    }

    function _registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) internal validParamsLength(params.length, getParametersTargetLenght()) {
        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, owner, token, params);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return currentParamsTargetLenght + dealProvider.currentParamsTargetLenght();
    }

    function getData(uint256 poolId) public override view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory dealProviderParams;
        (poolInfo, dealProviderParams) = dealProvider.getData(poolId);

        params = new uint256[](2);
        params[0] = dealProviderParams[0];  // leftAmount
        params[1] = startTimes[poolId];    // startTime
    }
}