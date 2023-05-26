// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract LockDealState is ERC721Enumerable {
    Counters.Counter public tokenIdCounter;
    address public vaultFactory;

    mapping(uint256 => address) public poolIdToProvider;
    mapping(uint256 => address) public poolIdToVault;
    mapping(address => address) public tokenToVault;
    mapping(address => bool) public approvedProviders;
}
