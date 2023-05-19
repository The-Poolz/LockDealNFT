// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./IDealProvierEvents.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract DealProviderState is IDealProvierEvents {
    LockDealNFT public nftContract;
    mapping(uint256 => Deal) public poolIdToDeal;
    uint256 public constant currentParamsTargetLenght = 1;

    function getParams(
        uint256 leftAmount
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = leftAmount;
    }
}
