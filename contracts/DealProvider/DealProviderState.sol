// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IDealProvierEvents.sol";
import "../Provider/ProviderModifiers.sol";
import "../interface/IProvider.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures, getters
abstract contract DealProviderState is IDealProvierEvents, ProviderModifiers, IProvider {
    mapping(uint256 => Deal) public poolIdToDeal;
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
    ) internal validParamsLength(params.length, currentParamsTargetLenght) {
        poolIdToDeal[poolId].leftAmount = params[0];
        poolIdToDeal[poolId].token = token;
        emit NewPoolCreated(BasePoolInfo(poolId, owner, token), params);
    }

    function getData(uint256 poolId) external override view returns (BasePoolInfo memory poolInfo, uint256[] memory params) {
        address token = poolIdToDeal[poolId].token;
        uint256 leftAmount = poolIdToDeal[poolId].leftAmount;
        address owner = lockDealNFT.exist(poolId) ? lockDealNFT.ownerOf(poolId) : address(0);
        poolInfo = BasePoolInfo(poolId, owner, token);
        params = new uint256[](1);
        params[0] = leftAmount; // leftAmount
    }
}
