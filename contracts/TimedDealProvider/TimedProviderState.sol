// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "../LockProvider/LockDealProvider.sol";
import "../Provider/ProviderModifiers.sol";
import "../interface/IProvider.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, getters
abstract contract TimedProviderState is IProvider, ProviderModifiers{
    LockDealProvider public dealProvider;
    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;
    uint256 public constant currentParamsTargetLenght = 2;

    struct TimedDeal {
        uint256 finishTime;
        uint256 startAmount;
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return currentParamsTargetLenght + dealProvider.currentParamsTargetLenght();
    }

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
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[3];
        dealProvider.registerPool(poolId, owner, token, params);
    }

    function getData(uint256 poolId) public override view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory baseLockDealProviderParams;
        (poolInfo, baseLockDealProviderParams) = dealProvider.getData(poolId);

        params = new uint256[](4);
        params[0] = baseLockDealProviderParams[0];  // leftAmount
        params[1] = baseLockDealProviderParams[1];  // startTime
        params[2] = poolIdToTimedDeal[poolId].finishTime; // finishTime
        params[3] = poolIdToTimedDeal[poolId].startAmount; // startAmount
    }
}
