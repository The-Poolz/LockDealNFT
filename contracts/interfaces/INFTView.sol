// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILockDealNFT.sol";

interface ILockDealNFTViews is ILockDealNFT {
    function balanceOf(address owner, address[] calldata tokenFilter) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index,
        address[] calldata tokenFilter
    ) external view returns (uint256 tokenId);
}
