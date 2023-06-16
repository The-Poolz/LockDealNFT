// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../ProviderInterface/IProviderExtend.sol";

contract RefundProvider is RefundState {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        dealProvider = provider;
    }

    ///@param params[params.length - 1] = refundMainCoinAmount
    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId, uint256 refundPoolId) {
        require(provider != address(0x0), "invalid provider address");
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);
        refundPoolId = lockDealNFT.mint(owner, token, msg.sender, params[params.length - 1]);
        IProviderExtend(provider).registerPool(poolId, owner, mainCoin, params);
        IProviderExtend(dealProvider).registerPool(refundPoolId, address(this), mainCoin, params);
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external {}

    function withdraw(uint256 poolId) external {}
}
