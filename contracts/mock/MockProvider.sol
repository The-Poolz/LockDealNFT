// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedDealProvider/TimedDealProvider.sol";
import "../interfaces/IFundsManager.sol";

/// @dev MockProvider is a contract for testing purposes.
contract MockProvider is IFundsManager {
    IProvider public _provider;
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _lockDealNFT, address __provider) {
        lockDealNFT = _lockDealNFT;
        _provider = IProvider(__provider);
    }

    function withdraw(uint256 poolId, uint256 amount) public {
        TimedDealProvider(address(_provider)).withdraw(poolId, amount);
    }

    function createNewPool(address[] calldata addresses, uint256[] memory params) public returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(addresses[0], addresses[1], addresses[0], params[0], _provider);
        _provider.registerPool(poolId, params);
    }

    function registerPool(uint256 poolId, uint256[] memory params) external {
        _provider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) public view returns (uint256[] memory params) {
        return _provider.getParams(poolId);
    }

    function handleWithdraw(uint256 poolId, uint256 mainCoinAmount) external {
        IFundsManager(address(_provider)).handleWithdraw(poolId, mainCoinAmount);
    }

    function handleRefund(uint256 poolId, uint256 tokenAmount, uint256 mainCoinAmount) external {
        IFundsManager(address(_provider)).handleRefund(poolId, tokenAmount, mainCoinAmount);
    }

    function registerNewRefundPool(address owner, IProvider provider) external returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, _provider);
        uint256 subPoolId = lockDealNFT.mintForProvider(owner, provider);
        uint256[] memory params = new uint256[](2);
        params[0] = subPoolId;
        params[1] = 1e21;
        _provider.registerPool(poolId, params);
    }

    function registerNewBundlePool(
        address owner,
        IProvider[] calldata providers,
        uint256[][] calldata providerParams
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, _provider);
        uint256 innerPoolId;
        for (uint256 i = 0; i < providers.length; ++i) {
            innerPoolId = lockDealNFT.mintForProvider(address(_provider), providers[i]);
            providers[i].registerPool(innerPoolId, providerParams[i]);
        }
        uint256[] memory params = new uint256[](1);
        params[0] = innerPoolId;
        _provider.registerPool(poolId, params);
    }
}
