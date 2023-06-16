// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../ProviderInterface/IProviderExtend.sol";
import "../ProviderInterface/IProvider.sol";
import "../Provider/ProviderModifiers.sol";

contract RefundProvider is RefundState, ProviderModifiers, IProvider {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        dealProvider = provider;
    }

    ///@param params[0] = tokenLeftAmount
    ///@param params[params.length - 2] = refundMainCoinAmount
    ///@param params[params.length - 1] = refund finish time
    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId) {
        uint256 providerLength = params.length;
        require(providerLength > 2, "invalid params length");

        /// XProvider       | Owner Refund  | Hold token (data)
        uint256 dataPoolID = lockDealNFT.mint(address(this), token, msg.sender, params[providerLength - 2], provider);
        IProviderExtend(provider).registerPool(dataPoolID, address(this), token, params);

        /// dealProvider    | Owner Refund  | Hold main coin
        uint256 dealProviderPoolId = lockDealNFT.mint(address(this), mainCoin, msg.sender, params[providerLength - 2], dealProvider);
        uint256 [] memory mainCoinAmount = new uint256[](1);
        mainCoinAmount[0] = params[providerLength - 2];
        IProviderExtend(dealProvider).registerPool(dealProviderPoolId, address(this), mainCoin, mainCoinAmount);

        /// refundProvider  | owner(user)   | real owner poolId
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0], address(this));
        IProviderExtend(provider).registerPool(poolId, owner, token, params);

        // store data to refund provider
        poolIdtoRefundDeal[poolId].refundAmount = params[providerLength - 2];
        poolIdtoRefundDeal[poolId].finishTime = params[providerLength - 1];
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {

    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public override onlyProvider {

        // uint256 _Ratio = (_NewAmount * 10**18) / leftAmount;
        // uint256 newPoolDebitedAmount = (pool.DebitedAmount * _Ratio) / 10**18;
        // uint256 newPoolStartAmount = (pool.StartAmount * _Ratio) / 10**18;
    }

    function withdrawRefundFunds(
        uint256 poolId,
        address to
    ) external onlyOwnerOrGov {
        if (poolIdtoRefundDeal[poolId].finishTime >= block.timestamp) {
            lockDealNFT.transferFrom(address(this), to, poolId);
            lockDealNFT.withdraw(poolId);
        }
    }

    function getData(
        uint256 poolId
    ) external view override returns (
        IDealProvierEvents.BasePoolInfo memory poolInfo,
        uint256[] memory params
    ) {

    }
}
