// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract LockDealNFT is ERC721, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;

    mapping(uint256 => address) public itemIdToProvider;
    mapping(address => bool) public approvedProviders;

    constructor() ERC721("LockDealNFT", "LDNFT") {}

    function mint(address to) public onlyApprovedProvider {
        _tokenIdCounter.increment();

        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        itemIdToProvider[newItemId] = msg.sender;
    }

    function setApprovedProvider(
        address provider,
        bool status
    ) public onlyOwner {
        approvedProviders[provider] = status;
    }

    modifier onlyApprovedProvider() {
        require(approvedProviders[msg.sender], "Provider not approved");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
