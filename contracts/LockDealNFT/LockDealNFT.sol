// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LockDealNFT is Ownable, ERC721Enumerable {
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
    ) external onlyOwner onlyContract(provider) {
        approvedProviders[provider] = status;
    }

    modifier onlyApprovedProvider() {
        require(approvedProviders[msg.sender], "Provider not approved");
        _;
    }

    modifier onlyContract(address contractAddress) {
        require(
            Address.isContract(contractAddress),
            "Invalid contract address"
        );
        _;
    }
}
