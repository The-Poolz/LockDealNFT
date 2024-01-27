// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";
import "../IFeeCollector.sol";

contract FeeDealProvider is DealProvider {
    IFeeCollector public feeCollector;

    constructor(IFeeCollector _feeCollector, ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        feeCollector = _feeCollector;
    }

    function withdraw(uint256 poolId) external override {
        require(feeCollector.feeCollected(), "FeeDealProvider: fee not collected");
        super.withdraw(poolId);
    }

    function name() external override pure returns (string memory) {
        return "FeeDealProvider";
    }
}
