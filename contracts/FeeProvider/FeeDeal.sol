// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";

contract FeeDealProvider is DealProvider {
    IFeeCollector public feeCollector;

    constructor(IFeeCollector feeCollector, ILockDealNFT lockDealNFT) DealProvider(lockDealNFT){
        this.feeCollector = feeCollector;
    }

    function withdraw(uint256 poolId) external override {
        require(feeCollector.feeCollected(), "FeeDealProvider: fee not collected");
        super.withdraw(poolId);
    }

    name() external override pure returns (string memory) {
        return "FeeDealProvider";
    }
}