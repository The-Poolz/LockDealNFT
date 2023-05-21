// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract LockDealState is ERC721Enumerable {
    Counters.Counter public _tokenIdCounter;

    mapping(uint256 => PoolInformation) public poolIdToPoolInformation;
    mapping(address => bool) public approvedProviders;
    mapping(address => address) public TokenToVault;
    struct PoolInformation{
        address Provider;
        address Vault;
    }
}
