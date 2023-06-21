// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../LockDealBundleProvider/LockDealBundleProvider.sol";
import "../LockDealNFT/LockDealNFT.sol";
import "../ProxyProvider/ProxyProvider.sol";

contract BundleFactory is IERC721Receiver {
    LockDealBundleProvider public lockDealBundleProvider;
    ProxyProvider public proxyProvider;
    LockDealNFT public lockDealNFT;
    mapping(address => uint256[]) public userToBundles;

    constructor(
        address _nftContract,
        address _BundleContract,
        address _proxyProvider
    ) {
        require(_BundleContract != address(0x0), "invalid address");
        require(_nftContract != address(0x0), "invalid address");
        require(_proxyProvider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
        lockDealBundleProvider = LockDealBundleProvider(_BundleContract);
        proxyProvider = ProxyProvider(_proxyProvider);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(validateToken(from, poolId), "invalid token");
        userToBundles[from].push(poolId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function validateToken(
        address user,
        uint256 poolId
    ) internal view returns (bool valid) {
        uint256[] memory bundles = userToBundles[user];
        if (bundles.length == 0) return true;
        address newToken = lockDealNFT.getTokenAddress(poolId);
        uint firstToken = lockDealNFT.getTokenAddress(bundles[0]);
        valid = newToken == firstToken;
    }

    function build() external {
        uint256[] memory bundles = userToBundles[msg.sender];
        require(bundles.length > 1, "no bundles"); //need 2+ pools to build a bundle
        uint256 firstId = lockDealNFT.tokenIdCounter.current();
        uint256[] memory params = new uint256[](bundles.length);
        for (uint256 i = 0; i < bundles.length; i++) {
            lockDealNFT.safeTransferFrom(
                address(this),
                address(proxyProvider),
                bundles[i]
            );
            params[i] = bundles[i];
            lockDealNFT.safeTransferFrom(
                address(this),
                address(lockDealBundleProvider),
                firstId + i
            );
        }
        address token = lockDealNFT.getTokenAddress(bundles[0]);
        uint256 poolId = lockDealNFT.mint(
            msg.sender,
            token,
            msg.sender,
            0,
            lockDealBundleProvider
        );
        lockDealBundleProvider._registerPool(poolId, msg.sender, token, params);
        userToBundles[msg.sender] = new uint256[](0);
    }

    function extract(uint256 poolid) external {
        require(
            lockDealNFT.ownerOf(poolid) == address(this),
            "not in contract"
        );
        RemoveIfOwner(msg.sender, poolid);
        lockDealNFT.safeTransferFrom(address(this), msg.sender, poolid);
    }

    function RemoveIfOwner(
        address user,
        uint256 poolId
    ) internal {
        bool valid = false;
        uint256 index = 0;
        uint256[] memory bundles = userToBundles[msg.sender];
        require(bundles.length > 0, "no bundles");
        for (index = 0; index < bundles.length; index++) {
            if (bundles[i] == poolId)
            {
                valid = true;
                break;
            }
        }
        require(valid, "not owner");
        bundles[index] = bundles[bundles.length - 1];
        bundles.pop();
        userToBundles[msg.sender] = bundles;
    }
}
