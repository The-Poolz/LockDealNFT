// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "../CollateralProvider/CollateralProvider.sol";
import "../ProviderInterface/IProviderSingleIdRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RefundProvider is RefundState, IERC721Receiver {
    constructor(address nftContract, address _collateralProvider, address _collectorProvider) {
        require(nftContract != address(0x0) && _collateralProvider != address(0x0) && _collectorProvider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        collateralProvider = CollateralProvider(_collateralProvider);
        collectorProvider = CollectorProvider(_collectorProvider);
    }

    ///@dev refund implementation
    function onERC721Received(
        address operator,
        address from,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "invalid nft contract");
        if (operator == from) {
            uint256 userDataPoolId = poolId + 1;
            uint256 refundPoolId = poolId + 2;
            uint256 collectorMainCoinId = poolId + 3;
            uint256 tokenPoolId = poolId + 4;
            (uint256 finishTime, uint256 mainCoinAmount) = collateralProvider.poolIdToTimedDeal(refundPoolId);
            require(finishTime > block.timestamp, "too late");
            DealProvider dealProvider = collectorProvider.lockProvider().dealProvider();

            // user takes new pool with refund tokens    
            uint256 newPoolId = lockDealNFT.mintForProvider(lockDealNFT.ownerOf(poolId), address(dealProvider));
            uint256[] memory params = new uint256[](1);
            params[0] = mainCoinAmount - collectorProvider.getParams(collectorMainCoinId)[0];
            dealProvider.registerPool(newPoolId, params);
            lockDealNFT.setPoolIdToVaultId(newPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
            lockDealNFT.setPoolIdToProvider(address(dealProvider), userDataPoolId);
            // refresh old token pool
            dealProvider.registerPool(userDataPoolId, new uint256[](1));

            // deposit tokens for collector
            collectorProvider.deposit(tokenPoolId, dealProvider.getParams(userDataPoolId)[0]);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    ///@param params[0] = tokenLeftAmount
    ///@param params[params.length - 3] = refundMainCoinAmount
    ///@param params[params.length - 2] = refund finish time
    ///@param params[params.length - 1] = RateInWei
    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId) {
        uint256 paramsLength = params.length;
        require(paramsLength > 3, "invalid params length");
        /// real owner poolId
        poolId = lockDealNFT.mintForProvider(owner, address(this));
        // Hold token (data) | Owner Refund  poolId + 1
        uint256 dataPoolID = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, params[0], provider);
        IProviderSingleIdRegistrar(provider).registerPool(dataPoolID, params);
        lockDealNFT.setPoolIdToVaultId(poolId, lockDealNFT.poolIdToVaultId(poolId + 1));
        // Hold main coin | Owner - ProjectOwner 
        uint256 [] memory mainCoinParams = new uint256[](3);
        mainCoinParams[0] = params[paramsLength - 3];
        mainCoinParams[1] = params[paramsLength - 2];
        mainCoinParams[2] = params[paramsLength - 1];
        // poolId + 2
        uint256 mainCoinPoolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, owner, mainCoinParams[1], address(collateralProvider));        
        // poolId + 3 
        lockDealNFT.mintForProvider(address(collateralProvider), address(collectorProvider));
        // poolId + 4
        lockDealNFT.mintForProvider(address(collateralProvider), address(collectorProvider));
        // save main coin pool data
        IProviderSingleIdRegistrar(collateralProvider).registerPool(mainCoinPoolId, mainCoinParams);
    }

    ///@dev split tokens and main coins into new pools
    function split(
        uint256 poolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external onlyNFT {
        uint256 refundPoolId = poolId + 2;
        uint256 userPoolId = poolId + 1;
        address provider = lockDealNFT.poolIdToProvider(userPoolId);
        // uint256 tokenLeftAmount = collateralProvider.dealProvider().poolIdToleftAmount(userPoolId);
        // uint256 mainCoinAmount = collateralProvider.dealProvider().poolIdToleftAmount(refundPoolId);
        // uint256 mainCoinSplitAmount = _calcAmount(splitAmount, _calcRate(tokenLeftAmount, mainCoinAmount));

        // IProvider(provider).split(userPoolId, newPoolId, splitAmount);

        // uint256 lockProviderPoolId = lockDealNFT.mintForProvider(lockDealNFT.ownerOf(refundPoolId), address(collateralProvider));
        // collateralProvider.split(refundPoolId, lockProviderPoolId, mainCoinSplitAmount);
        // lockDealNFT.setPoolIdToVaultId(lockProviderPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
        // poolIdToProjectOwner[lockProviderPoolId] = poolIdToProjectOwner[refundPoolId];

        lockDealNFT.mintForProvider(lockDealNFT.ownerOf(poolId), address(this));
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return rate != 0 ? (amount * 1e18) / rate : 0;
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        uint256 userPoolDataId = poolId + 1;
        uint256 refundPoolId = poolId + 2;
        uint256 collectorMainCoinId = poolId + 3;
        (withdrawnAmount, isFinal) = lockDealNFT.withdraw(userPoolDataId);
        uint256 rate = collateralProvider.rateInWei(refundPoolId);
        collectorProvider.deposit(collectorMainCoinId, _calcAmount(withdrawnAmount, rate));
    }
}
