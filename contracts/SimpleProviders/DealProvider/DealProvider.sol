// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DealProviderState.sol";
import "../Provider/BasicProvider.sol";
import "../../util/CalcUtils.sol";

contract DealProvider is DealProviderState, BasicProvider {
    using CalcUtils for uint256;

    constructor(ILockDealNFT _nftContract) {
        require(address(_nftContract) != address(0x0), "invalid address");
        lockDealNFT = _nftContract;
        name = "DealProvider";
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        if (poolData[poolId].length > 0 && poolData[poolId][0] >= amount) {
            poolData[poolId][0] -= amount;
            withdrawnAmount = amount;
            isFinal = poolData[poolId][0] == 0;
        }
    }

    /// @dev Splits a pool into two pools. Used by the LockedDealNFT contract or Provider
    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) public override onlyProvider {
        uint256 splitAmount = poolData[oldPoolId][0].calcAmount(ratio);
        require(poolData[oldPoolId][0] >= splitAmount, "Split amount exceeds the available amount");
        poolData[oldPoolId][0] -= splitAmount;
        poolData[newPoolId].push(splitAmount);
    }

    /**@dev Providers overrides this function to add additional parameters when creating a pool.
     * @param poolId The ID of the pool.
     * @param params An array of additional parameters.
     */
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override {
        if (poolData[poolId].length == 0) {
            poolData[poolId].push(params[0]);
        } else {
            poolData[poolId][0] = params[0];
        }
        emit UpdateParams(poolId, params);
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory) {
        return poolData[poolId]; // leftAmount
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        return poolData[poolId].length > 0 ? poolData[poolId][0] : 0;
    }
}
