// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProvider.sol";
import "./IFeeCollector.sol";

contract FeeDealProvider is DealProvider {
    IFeeCollector public feeCollector;

    constructor(IFeeCollector _feeCollector, ILockDealNFT _lockDealNFT) DealProvider(_lockDealNFT) {
        feeCollector = _feeCollector;
        name = "FeeDealProvider";
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override firewallProtectedSig(0x9e2bf22c) returns (uint256 withdrawnAmount, bool isFinal) {
        require(feeCollector.feeCollected(), "FeeDealProvider: fee not collected");
        return super._withdraw(poolId, amount);
    }
}
