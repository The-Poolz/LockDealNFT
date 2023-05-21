// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IProvider.sol";
import "./BaseLockDealModifiers.sol";

contract BaseLockDealProvider is BaseLockDealModifiers, ERC20Helper, IProvider {
    constructor(address nft,address provider) {
        dealProvider = DealProvider(provider);
        nftContract = LockDealNFT(nft);
    }

    /// params[0] = amount
    /// params[1] = startTime
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = nftContract.mint(owner, token, msg.sender, params[0]);
        registerPool(poolId, params);
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId
    ) public override returns (uint256 withdrawnAmount, bool isClosed) {
        if (startTimes[poolId] >= block.timestamp) {
            return dealProvider.withdraw(poolId);
        }
        return (0, false);
    }

    function split(
        uint256 poolId,
        uint256 splitAmount,
        address newOwner
    ) public override {
        dealProvider.split(poolId, splitAmount, newOwner);
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    )
        public
        onlyProvider
        validParamsLength(params.length, getParametersTargetLenght())
    {
        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, params);
    }

    function getParametersTargetLenght() public view returns (uint256) {
        return
            currentParamsTargetLenght +
            dealProvider.currentParamsTargetLenght();
    }
}
