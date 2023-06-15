// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../ProviderInterface/IProviderExtend.sol";

contract RefundProvider is RefundState {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        dealProvider = provider;
        //decimalsRate = 18;
    }

    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        uint256 mainCoinRate,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId, uint256 refundPoolId) {
        require(mainCoinRate > 0, "Invalid rate");
        require(provider != address(0x0), "invalid provider address");
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);

        uint256[] memory leftAmount = new uint256[](1);
        leftAmount[0] = getMainCoinAmount(params[0], mainCoinRate);
        refundPoolId = lockDealNFT.mint(owner, token, msg.sender, leftAmount[0]);

        IProviderExtend(provider).registerPool(poolId, owner, mainCoin, params);
        IProviderExtend(dealProvider).registerPool(refundPoolId, address(this), mainCoin, params);
    }

    function getMainCoinAmount(
        uint256 amount,
        uint256 rate
    ) internal pure returns (uint256) {
        return ((amount * 10 ** 18) / (rate * 10 ** 18)) / 10 ** 18;
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external {}

    function withdraw(uint256 poolId) external {}
}
