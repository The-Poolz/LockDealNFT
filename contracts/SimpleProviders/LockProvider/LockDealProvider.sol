// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/BasicProvider.sol";
import "./LockDealState.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

contract LockDealProvider is BasicProvider, LockDealState {
    constructor(ILockDealNFT _lockDealNFT, address _provider) {
        require(address(_lockDealNFT) != address(0x0) && _provider != address(0x0), "invalid address");
        provider = ISimpleProvider(_provider);
        lockDealNFT = _lockDealNFT;
        name = "LockDealProvider";
    }

    /// @dev use revert only for permissions
    function withdraw(uint256 poolId) public override onlyNFT sphereXGuardPublic(0xb6600ef5, 0x2e1a7d4d) returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getParams(poolId)[0]);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override sphereXGuardInternal(0xa0c6a1d4) returns (uint256 withdrawnAmount, bool isFinal) {
        withdrawnAmount = getWithdrawableAmount(poolId);
        (withdrawnAmount, isFinal) = provider.withdraw(poolId, amount > withdrawnAmount ? withdrawnAmount : amount);
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) public override onlyProvider sphereXGuardPublic(0x1b0498ed, 0xcaf0887d) {
        provider.split(oldPoolId, newPoolId, ratio);
        poolIdToTime[newPoolId] = poolIdToTime[oldPoolId];
    }

    function currentParamsTargetLenght() public view override(IProvider, ProviderState) returns (uint256) {
        return 1 + provider.currentParamsTargetLenght();
    }

    ///@param params[0] = amount
    ///@param params[1] = startTime
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override sphereXGuardInternal(0xce5ce0fd) {
        require(block.timestamp <= params[1], "Invalid start time");

        poolIdToTime[poolId] = params[1];
        provider.registerPool(poolId, params);
    }

    /**
     * @dev Retrieves the data of the specific pool identified by `poolId`
     * by calling the downstream cascading provider and adding own data.
     */
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = provider.getParams(poolId)[0]; // leftAmount
        params[1] = poolIdToTime[poolId]; // startTime
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return poolIdToTime[poolId] <= block.timestamp ? provider.getWithdrawableAmount(poolId) : 0;
    }
}
