// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";

contract MultiWithdrawState {
    ///@dev Each provider sets its own name
    string public name;
    ILockDealNFT public lockDealNFT;

    uint256 public maxPoolsPerTx;
}