// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "../Provider/ProviderState.sol";
import "./CollateralState.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CollateralProvider is
    IProviderSingleIdRegistrar,
    CollateralState,
    ProviderState,
    IERC721Receiver
{
    ///@dev withdraw tokens
    function onERC721Received(
        address operator,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "invalid nft contract");
        if (operator == from) {
            uint256 tokenPoolId = poolId + 1;
            DealProvider dealProvider = dealProvider.dealProvider();
            // create new pool with tokens
            uint256 newPoolId = lockDealNFT.mintForProvider(from, address(dealProvider));
            uint256[] memory params = new uint256[](1);
            params[0] = dealProvider.getParams(tokenPoolId)[0];
            dealProvider.registerPool(newPoolId, params);

            // return nft to owner
            lockDealNFT.transferFrom(address(this), from, poolId);
            // refresh old token poolId
            params[0] = 0;
            dealProvider.registerPool(tokenPoolId, params);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    constructor(address _lockDealNFT) {
        require(_lockDealNFT != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(_lockDealNFT);
    }

    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) external override {
        _registerPool(poolId, params);
    }

    ///@dev each provider decides how many parameters it needs by overriding this function
    ///@param params[0] = StartAmount
    ///@param params[1] = FinishTime
    ///@param params[2] = RateInWei
    function _registerPool(uint256 poolId, uint256[] memory params) internal {
        require(block.timestamp <= params[1], "Invalid start time");
        require(address(lockDealNFT.providerOf(poolId)) == address(this), "Invalid provider");
        require(
            lockDealNFT.ownerOf(poolId + 1) == address(this) &&
                lockDealNFT.ownerOf(poolId + 2) == address(this),
            "Invalid NFTs"
        );
        poolIdToTimedDeal[poolId] = TimedDeal(params[1], params[0]);
        rateInWei[poolId] = params[2];
    }

    function withdraw(
        uint256 poolId
    ) public returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, ) = lockDealNFT.withdraw(poolId);
        isFinal = poolIdToTimedDeal[poolId].finishTime < block.timestamp;
    }

    function getParams(
        uint256 poolId
    ) public view returns (uint256[] memory params) {
        params = new uint256[](3);
        params[0] = poolIdToTimedDeal[poolId].startAmount;
        params[1] = poolIdToTimedDeal[poolId].finishTime;
        params[2] = rateInWei[poolId];
    }
}
