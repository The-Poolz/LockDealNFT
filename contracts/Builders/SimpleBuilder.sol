// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../util/CalcUtils.sol";

/// @title SimpleBuilder contract
/// @notice Implements a contract for building refund simple providers
contract SimpleBuilder is ERC721Holder {
    using CalcUtils for uint256;
    ILockDealNFT public lockDealNFT;
    IProvider public refundProvider;
    IProvider public simpleProvider;
    IProvider public collateralProvider;

    constructor(ILockDealNFT _nft, IProvider _refund, IProvider _simpleProvider, IProvider _collateral) {
        lockDealNFT = _nft;
        refundProvider = _refund;
        simpleProvider = _simpleProvider;
        collateralProvider = _collateral;
    }

    struct UserPool {
        address user;
        uint256 amount;
    }

    /// @param userPools - array of user pools
    /// @param addressParams[0] = token
    /// @param addressParams[1] = mainCoin
    /// @param params[0] = collateral params, [0] start amount, [1] finish time
    /// @param params[1+][0] - amounts
    function buildRefundSimple(
        UserPool[] memory userPools,
        address[] calldata addressParams,
        uint256[] calldata params
    ) public {
        //TODO require
        require(userPools.length > 1, "invalid userPools length");
        require(addressParams.length > 1, "invalid addressParams length");
        require(params.length > 1, "invalid params length");
        uint256 firstRefundPoolId = lockDealNFT.totalSupply();
        (uint256 lastRefundPoolId, uint256 totalAmount) = _createRefundPools(addressParams, userPools);
        address mainCoin = addressParams[1];
        uint256 collateralPoolId = _createCollateralProvider(mainCoin, lastRefundPoolId, params);
        // register refund pools
        uint256 rateToWei = params[0].calcRate(totalAmount);
        _registerRefundPools(collateralPoolId, firstRefundPoolId, lastRefundPoolId, rateToWei);
    }

    function _createRefundPools(
        address[] calldata addressParams,
        UserPool[] memory userPools
    ) internal returns (uint256 lastPoolID, uint256 totalAmount) {
        address token = addressParams[0];
        uint256 length = userPools.length;
        uint256 userAmount;
        address user;
        for (uint256 i = 0; i < length; ++i) {
            userAmount = userPools[i].amount;
            user = userPools[i].user;
            // mint refund pools for users
            lastPoolID = lockDealNFT.mintAndTransfer(user, token, msg.sender, userAmount, refundProvider);
            // mint and save simple provider
            uint256 poolId = lockDealNFT.mintAndTransfer(
                address(refundProvider),
                token,
                msg.sender,
                userAmount,
                simpleProvider
            );
            uint256[] memory params = new uint256[](simpleProvider.currentParamsTargetLenght());
            params[0] = userAmount;
            simpleProvider.registerPool(poolId, params);
            totalAmount += userAmount;
        }
    }

    function _createCollateralProvider(
        address mainCoin,
        uint256 refundPoolId,
        uint256[] memory params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, msg.sender, params[0], collateralProvider);
        uint256[] memory collateralParams = new uint256[](3);
        collateralParams[0] = params[0];
        collateralParams[1] = params[1];
        collateralParams[2] = refundPoolId;
        collateralProvider.registerPool(poolId, collateralParams);
    }

    function _registerRefundPools(
        uint256 collateralPoolId,
        uint256 firstRefundPoolId,
        uint256 lastRefundPoolId,
        uint256 rateToWei
    ) internal {
        uint256[] memory params = new uint256[](2);
        params[0] = collateralPoolId;
        params[1] = rateToWei;
        for (uint256 i = firstRefundPoolId; i <= lastRefundPoolId; i += 2) {
            refundProvider.registerPool(i, params);
        }
    }
}
