// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/BasicProvider.sol";
import "./LockDealState.sol";

contract LockDealProvider is BasicProvider, LockDealState {
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        dealProvider = DealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    /// @dev use revert only for permissions
    function withdraw(
        address, address, uint256 poolId, bytes calldata
    ) public override onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getParams(poolId)[0]);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        if (startTimes[poolId] <= block.timestamp) {
            (withdrawnAmount, isFinal) = dealProvider.withdraw(poolId, amount);
        }
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyProvider {
        dealProvider.split(oldPoolId, newPoolId, splitAmount);
        startTimes[newPoolId] = startTimes[oldPoolId];
    }
        
    function currentParamsTargetLenght() public override view returns (uint256) {
        return 1 + dealProvider.currentParamsTargetLenght();
    }

    ///@param params[0] = amount
    ///@param params[1] = startTime
    function _registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) internal override {
        require(block.timestamp <= params[1], "Invalid start time");
        
        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, params);
    }
    
    /**
    * @dev Retrieves the data of the specific pool identified by `poolId`
    * by calling the downstream cascading provider and adding own data.
    */
    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = dealProvider.getParams(poolId)[0];  // leftAmount
        params[1] = startTimes[poolId];    // startTime
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return startTimes[poolId] <= block.timestamp ? dealProvider.getWithdrawableAmount(poolId) : 0;
    }
}