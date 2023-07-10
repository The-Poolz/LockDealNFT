// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract RefundProvider is RefundState, IERC721Receiver {
    constructor(address nftContract, address provider) {
        require(nftContract != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = LockDealNFT(nftContract);
        lockProvider = LockDealProvider(provider);
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
            uint256 refundPoolId = poolId - 1;
            uint256 userPoolId = poolId - 2;
            require(
                lockProvider.startTimes(refundPoolId) > block.timestamp,
                "too late"
            );
            DealProvider dealProvider = lockProvider.dealProvider();
            lockDealNFT.transferFrom(address(this), poolIdToProjectOwner[refundPoolId], userPoolId);
            lockDealNFT.transferFrom(address(this), receiver, refundPoolId);

            lockDealNFT.setPoolIdToProvider(address(dealProvider), userPoolId);
            lockDealNFT.setPoolIdToProvider(address(dealProvider), refundPoolId);
        }
        return IERC721Receiver.onERC721Received.selector;
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
        uint256 paramsLength = params.length;
        require(paramsLength > 2, "invalid params length");
        // Hold token (data) | Owner Refund
        uint256 dataPoolID = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, params[0], provider);
        IProvider(provider).registerPool(dataPoolID, params);

        // Hold main coin | Owner Refund
        uint256 [] memory mainCoinParams = new uint256[](2);
        mainCoinParams[0] = params[paramsLength - 2];
        mainCoinParams[1] = params[paramsLength - 1];
        uint256 lockProviderPoolId = lockDealNFT.mintAndTransfer(address(this), mainCoin, msg.sender, mainCoinParams[0], address(lockProvider));
        lockProvider.registerPool(lockProviderPoolId, mainCoinParams);
        poolIdToProjectOwner[lockProviderPoolId] = msg.sender;

        /// real owner poolId
        poolId = lockDealNFT.mintForProvider(owner, address(this));
    }

    function registerPool(uint256 poolId,uint256[] calldata params) external override onlyNFT {
        // will be implemented in the future
    }

    ///@dev split tokens and main coins into new pools
    function split(
        uint256 poolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external onlyNFT {
        uint256 refundPoolId = poolId - 1;
        uint256 userPoolId = poolId - 2;
        address provider = lockDealNFT.poolIdToProvider(userPoolId);
        uint256 tokenLeftAmount = lockProvider.dealProvider().poolIdToleftAmount(userPoolId);
        uint256 mainCoinAmount = lockProvider.dealProvider().poolIdToleftAmount(refundPoolId);
        uint256 mainCoinSplitAmount = _calcAmount(splitAmount, _calcRate(tokenLeftAmount, mainCoinAmount));

        IProvider(provider).split(userPoolId, newPoolId, splitAmount);

        uint256 lockProviderPoolId = lockDealNFT.mintForProvider(lockDealNFT.ownerOf(refundPoolId), address(lockProvider));
        lockProvider.split(refundPoolId, lockProviderPoolId, mainCoinSplitAmount);
        lockDealNFT.setPoolIdToVaultId(lockProviderPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
        poolIdToProjectOwner[lockProviderPoolId] = poolIdToProjectOwner[refundPoolId];

        lockDealNFT.mintForProvider(lockDealNFT.ownerOf(poolId), address(this));
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return tokenBValue != 0 ? (tokenAValue * 1e18) / tokenBValue : 0;
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return rate != 0 ? (amount * 1e18) / rate : 0;
    }

    function withdraw(
        uint256 poolId
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        uint256 refundPoolId = poolId - 1;
        uint256 userPoolId = poolId - 2;
        // user withdraws his token from the provider by cascading providers params
        DealProvider dealProvider = lockProvider.dealProvider();
        uint256 tokenAmount = dealProvider.poolIdToleftAmount(userPoolId);
        (withdrawnAmount, isFinal) = lockDealNFT.withdraw(userPoolId);
        // lockProvider.startTimes(poolId - 1) is time limit when the main coin pool is active
        if (withdrawnAmount > 0 && lockProvider.startTimes(refundPoolId) >= block.timestamp) {
            uint256 mainCoinAmount = lockProvider.dealProvider().poolIdToleftAmount(refundPoolId);
            uint256 withdrawMainCoinAmount = _calcAmount(withdrawnAmount, _calcRate(tokenAmount, mainCoinAmount));
            // create new pool for the main withdrawn coins
            uint256 mainCoinPoolId = lockDealNFT.mintForProvider(poolIdToProjectOwner[refundPoolId], address(dealProvider));
            lockDealNFT.setPoolIdToVaultId(mainCoinPoolId, lockDealNFT.poolIdToVaultId(refundPoolId));
            dealProvider.split(refundPoolId, mainCoinPoolId, withdrawMainCoinAmount);
        }
    }
}
