// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProvider.sol";
import "../LockDealNFT/LockDealNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RefundState is Ownable {
    LockDealNFT public lockDealNFT;
    address public dealProvider;
    mapping(uint256 => address) public poolIdToProvider;
    // uint256 public decimalsRate;

    // function setDecimalRate(uint256 decimals) external onlyOwner {
    //     decimalsRate = decimals;
    // }
}
