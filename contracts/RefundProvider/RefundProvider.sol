// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RefundProvider is RefundState, IERC721Receiver {
    constructor(address nftContract, address provider) {
        require(
            nftContract != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        lockDealNFT = LockDealNFT(nftContract);
        collateralProvider = CollateralProvider(provider);
    }

    ///@dev refund implementation
    function onERC721Received(
        address provider,
        address receiver,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "invalid nft contract");
        if (provider == receiver) {
            require(
                collateralProvider.startTimes(poolIdToCollateralId[poolId]) > block.timestamp,
                "too late"
            );
            // create main coin pool for user
            DealProvider dealProvider = collateralProvider.dealProvider();
            lockDealNFT.mintForProvider(receiver, address(dealProvider));
            // uint256 calcAmount = _calcMainCoinAmount(poolIdToRateToWei[poolId], ;
            // dealProvider.register()
            // calculate main coin amount

            // register main coin pool data
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    ///@param params[0] = tokenLeftAmount
    ///@param params[params.length - 3] = refundMainCoinAmount
    ///@param params[params.length - 2] = rateToWei
    ///@param params[params.length - 1] = refund finish time
    function createNewRefundPool(
        address token,
        address owner,
        address mainCoin,
        address provider,
        uint256[] calldata params
    ) external returns (uint256 poolId) {
        uint256 paramsLength = params.length;
        require(paramsLength > 3, "invalid params length");
        // create new refund pool | Owner User
        poolId = lockDealNFT.mintForProvider(owner, address(this));

        // Hold token (data) | Owner Refund Provider
        uint256 dataPoolID = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, params[0], provider);
        IProvider(provider).registerPool(dataPoolID, params);

        // Hold main coin | Project Owner 
        uint256 collateralPoolId = lockDealNFT.mintAndTransfer(address(this), mainCoin, msg.sender, params[paramsLength - 3], address(collateralProvider));
        uint256[] memory collateralParams = new uint256[](2);
        collateralParams[0] = params[paramsLength - 3];
        collateralParams[1] = params[paramsLength - 1];
        collateralProvider.registerPool(collateralPoolId, collateralParams);
        // save vaults ids
        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 1);
        lockDealNFT.copyVaultId(dataPoolID, collateralPoolId + 2);
        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 3);
        lockDealNFT.transferFrom(address(this), msg.sender, collateralPoolId);
        // save refund data
        uint256[] memory refundRegisterParams = new uint256[](currentParamsTargetLenght());
        refundRegisterParams[0] = collateralPoolId;
        refundRegisterParams[1] = params[paramsLength - 2];
        _registerPool(poolId, refundRegisterParams);
    }

    ///@param params[0] = collateralId
    ///@param params[1] = rateToWei
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    )
        public
        override
        onlyProvider
    {
        _registerPool(poolId, params);
    }

    function _registerPool(uint256 poolId, uint256[] memory params)
        internal
        validParamsLength(params.length, currentParamsTargetLenght())
    {
        poolIdToCollateralId[poolId] = params[0];
        poolIdToRateToWei[poolId] = params[1];
    }

    ///@dev split tokens and main coins into new pools
    function split(
        uint256 poolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external onlyNFT {
        // uint256 refundPoolId = poolId - 1;
        // uint256 userPoolId = poolId - 2;
        // address provider = lockDealNFT.poolIdToProvider(userPoolId);
        // uint256 tokenLeftAmount = lockProvider.dealProvider().poolIdToleftAmount(userPoolId);
        // uint256 mainCoinAmount = lockProvider.dealProvider().poolIdToleftAmount(refundPoolId);
        // uint256 mainCoinSplitAmount = _calcAmount(splitAmount, _calcRate(tokenLeftAmount, mainCoinAmount));
        // IProvider(provider).split(userPoolId, newPoolId, splitAmount);
        // uint256 lockProviderPoolId = lockDealNFT.mintForProvider(lockDealNFT.ownerOf(refundPoolId), address(lockProvider));
        // lockProvider.split(refundPoolId, lockProviderPoolId, mainCoinSplitAmount);
        // lockDealNFT.setPoolIdToVaultId(lockProviderPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
        // poolIdToProjectOwner[lockProviderPoolId] = poolIdToProjectOwner[refundPoolId];
        // lockDealNFT.mintForProvider(lockDealNFT.ownerOf(poolId), address(this));
    }

    function _calcRate(
        uint256 tokenAValue,
        uint256 tokenBValue
    ) internal pure returns (uint256) {
        return tokenBValue != 0 ? (tokenAValue * 1e18) / tokenBValue : 0;
    }

    function _calcAmount(
        uint256 amount,
        uint256 rate
    ) internal pure returns (uint256) {
        return rate != 0 ? (amount * 1e18) / rate : 0;
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        uint256 refundPoolId = poolId - 1;
        uint256 userPoolId = poolId - 2;
        // user withdraws his token from the provider by cascading providers params
        // DealProvider dealProvider = lockProvider.dealProvider();
        // uint256 tokenAmount = dealProvider.poolIdToleftAmount(userPoolId);
        // (withdrawnAmount, isFinal) = lockDealNFT.withdraw(userPoolId);
        // // lockProvider.startTimes(poolId - 1) is time limit when the main coin pool is active
        // if (withdrawnAmount > 0 && lockProvider.startTimes(refundPoolId) >= block.timestamp) {
        //     uint256 mainCoinAmount = lockProvider.dealProvider().poolIdToleftAmount(refundPoolId);
        //     uint256 withdrawMainCoinAmount = _calcAmount(withdrawnAmount, _calcRate(tokenAmount, mainCoinAmount));
        //     // create new pool for the main withdrawn coins
        //     uint256 mainCoinPoolId = lockDealNFT.mintForProvider(poolIdToProjectOwner[refundPoolId], address(dealProvider));
        //     lockDealNFT.setPoolIdToVaultId(mainCoinPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
        //     dealProvider.split(refundPoolId, mainCoinPoolId, withdrawMainCoinAmount);
        // }
    }
}
