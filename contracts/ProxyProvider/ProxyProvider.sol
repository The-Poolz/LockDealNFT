// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./ProxyState.sol";
import "../Provider/BasicProvider.sol";
import "../Provider/ProviderState.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ProxyProvider is
    ProxyState,
    ProviderState,
    BasicProvider,
    IERC721Receiver
{
    constructor(address _nftContract) {
        require(_nftContract != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_nftContract);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        uint256[] memory params = new uint256[](1);
        params[0] = poolId;
        address token = lockDealNFT.poolIdToToken(poolId);
        lockDealNFT.mint(from, token, from, 0, address(this));
        _registerPool(poolId, from, token, params);
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @dev Registers a new pool in the proxy
    /// @param poolId The ID of the new pool
    /// @param owner The owner of the pool
    /// @param token The address of the token
    /// @param params[0] The ID of the old pool
    function _registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) internal override {
        address provider = lockDealNFT.poolIdToProvider(poolId);
        require(provider != address(this), "cannot proxy a proxy");
        PoolIdtoProxyData[poolId] = ProxyData({
            Provider: provider,
            PoolId: params[0]
        });
        lockDealNFT.overrideVaultId(poolId, params[0]);
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (BasicProvider provider, ProxyData memory proxyData) = getBasicProvider(
            poolId
        );
        (withdrawnAmount, isFinal) = provider.withdraw(proxyData.PoolId);
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyNFT {
        (BasicProvider provider, ProxyData memory proxyData) = getBasicProvider(
            oldPoolId
        );
        provider.split(proxyData.PoolId, newPoolId, splitAmount);
    }

    function getData(
        uint256 poolId
    )
        public
        view
        override
        returns (
            IDealProvierEvents.BasePoolInfo memory poolInfo,
            uint256[] memory params
        )
    {
        (BasicProvider provider, ProxyData memory proxyData) = getBasicProvider(
            poolId
        );
        (poolInfo, params) = provider.getData(proxyData.PoolId);
    }

    function getBasicProvider(
        uint256 poolId
    ) public view returns (BasicProvider provider, ProxyData memory proxyData) {
        ProxyData memory proxyData = PoolIdtoProxyData[poolId];
        provider = BasicProvider(proxyData.Provider);
    }
}
