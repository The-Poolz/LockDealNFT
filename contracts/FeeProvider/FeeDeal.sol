// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";
import "../interfaces/IFeeCollector.sol"; // Ensure this import is correct based on your project structure

contract FeeDealProvider is DealProvider {
    IFeeCollector public feeCollector;

    // Adjusted constructor to use proper assignment syntax
    constructor(IFeeCollector _feeCollector, ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        feeCollector = _feeCollector;
    }

    // Fixed override syntax and function visibility
    function withdraw(uint256 poolId) external override {
        require(feeCollector.feeCollected(), "FeeDealProvider: fee not collected");
        super.withdraw(poolId);
    }

    // Corrected function syntax
    function name() external override pure returns (string memory) {
        return "FeeDealProvider";
    }
}
