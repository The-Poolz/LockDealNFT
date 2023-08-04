// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RefundState.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../util/CalcUtils.sol";

contract RefundProvider is RefundState, IERC721Receiver {
    using CalcUtils for uint256;

    constructor(ILockDealNFT nftContract, address provider) {
        require(
            address(nftContract) != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        lockDealNFT = nftContract;
        collateralProvider = CollateralProvider(provider);
        name = "RefundProvider";
    }

    ///@dev refund implementation
    function onERC721Received(
        address provider,
        address user,
        uint256 poolId,
        bytes calldata
    ) external override returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "invalid nft contract");
        if (provider == user) {
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            require(
                collateralProvider.poolIdToTime(collateralPoolId) > block.timestamp,
                "too late"
            );
            ISimpleProvider dealProvider = collateralProvider.provider();
            uint256 userDataPoolId = poolId + 1;
            // user withdraws his tokens
            uint256 amount = dealProvider.getParams(userDataPoolId)[0];
            (uint256 withdrawnAmount, ) = dealProvider.withdraw(userDataPoolId, amount);
            uint256 mainCoinAmount = withdrawnAmount.calcAmount(poolIdToRateToWei[poolId]);
            collateralProvider.handleRefund(collateralPoolId, withdrawnAmount, mainCoinAmount);
            uint256 newMainCoinPoolId = lockDealNFT.mintForProvider(user, dealProvider);
            uint256[] memory params = new uint256[](1);
            params[0] = mainCoinAmount;
            dealProvider.registerPool(newMainCoinPoolId, params);
            lockDealNFT.copyVaultId(collateralPoolId, newMainCoinPoolId);
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
        IProvider provider,
        uint256[] calldata params
    ) external returns (uint256 poolId) {
        uint256 paramsLength = params.length;
        require(paramsLength > 3, "invalid params length");
        // create new refund pool | Owner User
        poolId = lockDealNFT.mintForProvider(owner, this);

        // Hold token (data) | Owner Refund Provider
        uint256 dataPoolID = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, params[0], provider);
        provider.registerPool(dataPoolID, params);

        // Hold main coin | Project Owner 
        uint256 collateralPoolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, msg.sender, params[paramsLength - 3], collateralProvider);
        uint256[] memory collateralParams = new uint256[](2);
        collateralParams[0] = params[paramsLength - 3];
        collateralParams[1] = params[paramsLength - 1];
        collateralProvider.registerPool(collateralPoolId, collateralParams);
        // save vaults ids
        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 1);
        lockDealNFT.copyVaultId(dataPoolID, collateralPoolId + 2);
        lockDealNFT.copyVaultId(collateralPoolId, collateralPoolId + 3);
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
        lockDealNFT.updateProviderMetadata(poolId);
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
        uint256 ratio
    ) external onlyNFT {
        _registerPool(newPoolId, getParams(poolId));
        uint256 userPoolId = poolId + 1;
        lockDealNFT.split(userPoolId, ratio, address(this));
    }

    ///@dev user withdraws his tokens
    function withdraw(
        address operator, address from, uint256 poolId, bytes calldata data
    ) public override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        uint256 userDataPoolId = poolId + 1;
        // user withdraws his tokens
        (withdrawnAmount, isFinal) = lockDealNFT.poolIdToProvider(userDataPoolId).withdraw(operator, from, userDataPoolId, data);
        if(collateralProvider.poolIdToTime(poolIdToCollateralId[poolId]) >= block.timestamp) {
            uint256 mainCoinAmount = withdrawnAmount.calcAmount(poolIdToRateToWei[poolId]);
            collateralProvider.handleWithdraw(poolIdToCollateralId[poolId], mainCoinAmount);
        }
        lockDealNFT.updateProviderMetadata(poolId);
    }
}