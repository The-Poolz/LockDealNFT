// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IDeposit.sol";
import "./CollateralState.sol";

contract CollateralProvider is BasicProvider, CollateralState {
    IDeposit public depositProvider;

    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        depositProvider = IDeposit(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    ///@dev each provider decides how many parameters it needs by overriding this function
    ///@param params[0] = FinishTime
    ///@param params[1] = StartAmount
    ///@param params[2] = RateInWei
    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal override {
        require(block.timestamp <= params[0], "Invalid start time");
        require(
            LockDealProvider.lockDealNFT.ownerOf(poolId + 1) == address(this) &&
                LockDealProvider.lockDealNFT.ownerOf(poolId + 2) ==
                address(this),
            "Invalid NFTs"
        );
        poolIdToTimedDeal[poolId] = TimedDeal(params[0], params[1]);
        RateInWei[poolId] = params[2];
    }
}
