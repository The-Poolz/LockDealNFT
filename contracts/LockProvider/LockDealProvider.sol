// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LockDealState.sol";

contract LockDealProvider is LockDealState {
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        dealProvider = DealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    ///@param params[0] = amount
    ///@param params[1] = startTime
    ///@dev requirements are in mint, _register functions
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mint(owner,  token, msg.sender, params[0]);
        _registerPool(poolId, owner, token, params);
    }

    /// @dev use revert only for permissions
    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (, uint256[] memory params) = getData(poolId);
        uint256 leftAmount = params[0];
        
        (withdrawnAmount, isFinal) = _withdraw(poolId, leftAmount);
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, amount);
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal returns (uint256 withdrawnAmount, bool isFinal) {
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
}
