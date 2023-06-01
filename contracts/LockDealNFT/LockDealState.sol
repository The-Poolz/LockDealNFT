// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "poolz-helper-v2/contracts/interfaces/IVaultManager.sol";

abstract contract LockDealState is ERC721Enumerable {
    Counters.Counter public tokenIdCounter;
    IVaultManager public vaultManager;

    mapping(uint256 => address) public poolIdToProvider;
    mapping(uint256 => uint256) public poolIdToVaultId;
    mapping(address => bool) public approvedProviders;
}
