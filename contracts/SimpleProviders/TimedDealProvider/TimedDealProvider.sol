// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";
import "../DealProvider/DealProviderState.sol";
import "../Provider/BasicProvider.sol";
import "../../util/CalcUtils.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

contract TimedDealProvider is LockDealState, DealProviderState, BasicProvider {
    using CalcUtils for uint256;

    /**
     * @dev Contract constructor.
     * @param _lockDealNFT The address of the LockDealNFT contract.
     * @param _provider The address of the LockProvider contract.
     */
    constructor(ILockDealNFT _lockDealNFT, address _provider) {
        require(address(_lockDealNFT) != address(0x0) && _provider != address(0x0), "invalid address");
        provider = ISimpleProvider(_provider);
        lockDealNFT = _lockDealNFT;
        name = "TimedDealProvider";
    }
    
    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override sphereXGuardInternal(0x4400dac3) returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = provider.withdraw(poolId, amount);
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        uint256[] memory params = getParams(poolId);
        uint256 leftAmount = params[0];
        uint256 startTime = params[1];
        uint256 finishTime = params[2];
        uint256 startAmount = params[3];

        if (block.timestamp < startTime) return 0;
        if (finishTime <= block.timestamp) return leftAmount;

        uint256 totalPoolDuration = finishTime - startTime;
        uint256 timePassed = block.timestamp - startTime;
        uint256 debitableAmount = (startAmount * timePassed) / totalPoolDuration;
        return debitableAmount - (startAmount - leftAmount);
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) public onlyProvider sphereXGuardPublic(0x2b6b4212, 0xcaf0887d) {
        provider.split(oldPoolId, newPoolId, ratio);
        uint256 newPoolStartAmount = poolIdToAmount[oldPoolId].calcAmount(ratio);
        poolIdToAmount[oldPoolId] -= newPoolStartAmount;
        poolIdToAmount[newPoolId] = newPoolStartAmount;
        poolIdToTime[newPoolId] = poolIdToTime[oldPoolId];
    }

    ///@param params[0] = leftAmount = startAmount (leftAmount & startAmount must be same while creating pool)
    ///@param params[1] = startTime
    ///@param params[2] = finishTime
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override sphereXGuardInternal(0x96aa4b2f) {
        require(params[2] >= params[1], "Finish time should be greater than start time");
        poolIdToTime[poolId] = params[2];
        poolIdToAmount[poolId] = params[0];
        provider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        uint256[] memory lockDealProviderParams;
        lockDealProviderParams = provider.getParams(poolId);

        params = new uint256[](4);
        params[0] = lockDealProviderParams[0]; // leftAmount
        params[1] = lockDealProviderParams[1]; // startTime
        params[2] = poolIdToTime[poolId]; // finishTime
        params[3] = poolIdToAmount[poolId]; // startAmount
    }

    function currentParamsTargetLenght() public view override(IProvider, ProviderState) returns (uint256) {
        return 1 + provider.currentParamsTargetLenght();
    }
}
