// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "./ProxyState.sol";
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

    function pack(address from, uint256 poolId) internal {
        uint256[] memory params = new uint256[](1);
        params[0] = poolId;
        //address token = lockDealNFT.tokenOf(poolId); // will be after #116
        address token = address(0); // TODO remove after #116
        lockDealNFT.mint(from, token, from, 0, address(this));
        _registerPool(poolId, from, token, params);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        if (lockDealNFT.poolIdToProvider(poolId) == address(this)) {
            unpack(from, poolId);
        } else {
            pack(from, poolId);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function unpack(address to, uint256 poolId) internal {
        require(lockDealNFT.ownerOf(poolId) == address(this), "not owner");
        ProxyData memory proxyData = getThisData(poolId);
        lockDealNFT.safeTransferFrom(address(this), to, proxyData.PoolId);
        lockDealNFT.overrideVaultId(poolId, proxyData.PoolId);
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
            Provider: BasicProvider(provider),
            PoolId: params[0]
        });
        lockDealNFT.overrideVaultId(poolId, params[0]);
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        ProxyData memory proxyData = getThisData(poolId);
        (withdrawnAmount, isFinal) = proxyData.Provider.withdraw(proxyData.PoolId);
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyNFT {
        ProxyData memory proxyData = getThisData(oldPoolId);
        proxyData.Provider.split(proxyData.PoolId, newPoolId, splitAmount);
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
        ProxyData memory proxyData = getThisData(poolId);
        (poolInfo, params) = proxyData.Provider.getData(proxyData.PoolId);
    }

    function getThisData(
        uint256 poolId
    ) public view returns (ProxyData memory proxyData) {
        ProxyData memory proxyData = PoolIdtoProxyData[poolId];
    }
}
