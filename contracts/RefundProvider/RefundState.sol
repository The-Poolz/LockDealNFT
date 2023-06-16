// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProvider.sol";
import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/GovManager.sol";

contract RefundState is GovManager {
    address public dealProvider;
    mapping(uint256 => RefundDeal) public poolIdtoRefundDeal;
    //mapping(uint256 => address) public poolIdToProvider;

    struct RefundDeal {
        uint256 refundAmount;
        uint256 finishTime; // after this time, the owner can return the funds back
    }
}
