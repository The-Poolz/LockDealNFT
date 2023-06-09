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
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (, uint256[] memory params) = getData(poolId);
        uint256 leftAmount = params[0];
        
        (withdrawnAmount, isFinal) = _withdraw(poolId, leftAmount);
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
        address owner,
        address token,
        uint256[] memory params
    ) internal override {
        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, owner, token, params);
    }
    
    /**
    * @dev Retrieves the data of the specific pool identified by `poolId`
    * by calling the downstream cascading provider and adding own data.
    */
    function getData(uint256 poolId) public override view returns (IDealProvierEvents.BasePoolInfo memory poolInfo, uint256[] memory params) {
        uint256[] memory dealProviderParams;
        (poolInfo, dealProviderParams) = dealProvider.getData(poolId);

        params = new uint256[](2);
        params[0] = dealProviderParams[0];  // leftAmount
        params[1] = startTimes[poolId];    // startTime
    }
}
