// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedDealProvider/TimedDealProvider.sol";
import "../interfaces/IFundsManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

/// @dev MockProvider is a contract for testing purposes.
contract MockProvider is IFundsManager , SphereXProtected {
    IProvider public _provider;
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _lockDealNFT, address __provider) {
        lockDealNFT = _lockDealNFT;
        _provider = IProvider(__provider);
    }

    function withdraw(uint256 poolId, uint256 amount) public sphereXGuardPublic(0x46be1be1, 0x441a3e70) {
        TimedDealProvider(address(_provider)).withdraw(poolId, amount);
    }

    function createNewPool(
        address[] calldata addresses,
        uint256[] memory params,
        bytes calldata signature
    ) public sphereXGuardPublic(0xde90f28e, 0x14877c38) returns (uint256 poolId) {
        poolId = lockDealNFT.safeMintAndTransfer(
            addresses[0],
            addresses[1],
            addresses[0],
            params[0],
            _provider,
            signature
        );
        _provider.registerPool(poolId, params);
    }

    function createNewPoolWithTransfer(
        address[] calldata addresses,
        uint256[] memory params
    ) public sphereXGuardPublic(0x874d474d, 0x45d09581) returns (uint256 poolId) {
        IERC20(addresses[1]).transferFrom(addresses[0], address(lockDealNFT), params[0]);
        poolId = lockDealNFT.mintAndTransfer(addresses[0], addresses[1], params[0], _provider);
        _provider.registerPool(poolId, params);
    }

    function registerPool(uint256 poolId, uint256[] memory params) external sphereXGuardExternal(0x79f15fcc) {
        _provider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) public view returns (uint256[] memory params) {
        return _provider.getParams(poolId);
    }

    function handleWithdraw(uint256 poolId, uint256 tokenAmount) external sphereXGuardExternal(0xe0e26ca1) {
        IFundsManager(address(_provider)).handleWithdraw(poolId, tokenAmount);
    }

    function handleRefund(uint256 poolId, address user, uint256 tokenAmount) external sphereXGuardExternal(0x199e7e3d) {
        IFundsManager(address(_provider)).handleRefund(poolId, user, tokenAmount);
    }

    function registerNewRefundPool(address owner, IProvider provider) external sphereXGuardExternal(0xd4f6a256) returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(owner, _provider);
        lockDealNFT.mintForProvider(address(_provider), provider); // poolId + 1 for Refund Provider
        uint256 collateralPoolId = lockDealNFT.mintForProvider(owner, provider);
        uint256[] memory params = new uint256[](1);
        params[0] = collateralPoolId;
        _provider.registerPool(poolId, params);
    }

    function registerNewBundlePool(
        address owner,
        IProvider[] calldata providers,
        uint256[][] calldata providerParams
    ) public sphereXGuardPublic(0xcc8fefd4, 0x2e7d0788) returns (uint256 poolId) {
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
