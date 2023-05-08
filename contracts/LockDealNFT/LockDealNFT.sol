// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LockDealNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => address) public itemIdToProvider;
    mapping(address => bool) public approvedProviders;

    constructor() ERC721("LockDealNFT", "LDNFT") {}

    function mint(address to) public onlyApprovedProvider {
        _tokenIdCounter.increment();

        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        itemIdToProvider[newItemId] = msg.sender;
    }

    function setApprovedProvider(address provider, bool status) public onlyOwner {
        approvedProviders[provider] = status;
    }

    modifier onlyApprovedProvider {
        require(approvedProviders[msg.sender], "Provider not approved");
        _;
    }
}
