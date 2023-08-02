// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/TimedDealProvider/TimedDealProvider.sol";
import "../interfaces/IFundsManager.sol";

/// @dev MockProvider is a contract for testing purposes.
contract MockProvider is IFundsManager {
    address public provider;
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _lockDealNFT, address _provider) {
        lockDealNFT = _lockDealNFT;
        provider = _provider;
    }

    function withdraw(uint256 poolId, uint256 amount) public {
        TimedDealProvider(provider).withdraw(poolId, amount);
    }

    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(owner, token, owner, params[0], IProvider(provider));
        TimedDealProvider(provider).registerPool(poolId, params);
    }

    function registerPool(
        uint256 poolId,
        uint256[] memory params
    ) external {
        IProvider(provider).registerPool(poolId, params);
    }

    function getParams(
        uint256 poolId
    ) public view returns (uint256[] memory params) {
        return TimedDealProvider(provider).getParams(poolId);
    }

    function handleWithdraw(uint256 poolId, uint256 mainCoinAmount) external {
        IFundsManager(provider).handleWithdraw(poolId, mainCoinAmount);
    }

    function handleRefund(
        uint256 poolId,
        uint256 tokenAmount,
        uint256 mainCoinAmount
    ) external {
        IFundsManager(provider).handleRefund(poolId, tokenAmount, mainCoinAmount);
    }
}
