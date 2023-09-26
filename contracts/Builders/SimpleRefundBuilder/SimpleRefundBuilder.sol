// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../../interfaces/ISimpleProvider.sol";
import "../Builder/BuilderInternal.sol";
import "../../util/CalcUtils.sol";

/// @title SimpleRefundBuilder contract
/// @notice Implements a contract for building refund simple providers
contract SimpleRefundBuilder is ERC721Holder, BuilderInternal {
    using CalcUtils for uint256;
    IProvider public refundProvider;
    IProvider public collateralProvider;

    constructor(ILockDealNFT _nft, IProvider _refund, IProvider _collateral) {
        lockDealNFT = _nft;
        refundProvider = _refund;
        collateralProvider = _collateral;
    }

    /// @param userData - array of user pools
    /// @param addressParams[0] = token
    /// @param addressParams[1] = mainCoin
    /// @param addressParams[2] = simpleProvider
    /// @param params[0] = collateral params, [0] start amount, [1] finish time
    /// @param params[1] = Array of params for simpleProvider. May be empty if this is DealProvider
    function buildRefundSimple(
        Builder calldata userData,
        address[] calldata addressParams,
        uint256[][] calldata params
    ) public {
        require(userData.userPools.length > 0, "invalid userPools length");
        require(addressParams.length > 2, "invalid addressParams length");
        require(params.length > 1, "invalid params length");
        require(userData.totalAmount > 0, "invalid totalAmount");
        uint256 firstRefundPoolId = lockDealNFT.totalSupply();
        uint256 lastRefundPoolId = _createSimpleRefundPools(addressParams, userData, params[1]);
        address mainCoin = addressParams[1];
        uint256 collateralPoolId = _createCollateralProvider(mainCoin, lastRefundPoolId, params[0]);
        // register refund pools
        uint256 mainCoinAmount = params[0][0];
        uint256 rateToWei = mainCoinAmount.calcRate(userData.totalAmount);
        _registerRefundPools(collateralPoolId, firstRefundPoolId, lastRefundPoolId, rateToWei);
    }

    function _createSimpleRefundPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[] memory params
    ) internal returns (uint256 lastPoolId) {
        address token = addressParams[0];
        uint256 totalAmount = userData.totalAmount;
        ISimpleProvider simpleProvider = ISimpleProvider(addressParams[2]);
        // one time transfer for deacrease number transactions
        uint256 tokenPoolId = lockDealNFT.mintAndTransfer(
            userData.userPools[0].user,
            token,
            msg.sender,
            totalAmount,
            refundProvider
        );
        params = _concatParams(userData.userPools[0].amount, params);
        totalAmount -= _createNewNFT(simpleProvider, tokenPoolId, userData.userPools[0], params);
        uint256 length = userData.userPools.length;
        for (uint256 i = 1; i < length; ++i) {
            uint256 userAmount = userData.userPools[i].amount;
            address user = userData.userPools[i].user;
            // mint refund pools for users
            lockDealNFT.mintForProvider(user, refundProvider);
            params[0] = userAmount;
            totalAmount -= _createNewNFT(simpleProvider, tokenPoolId, userData.userPools[i], params);
        }
        lastPoolId = lockDealNFT.totalSupply() - 2;
        assert(totalAmount == 0);
    }

    function _createCollateralProvider(
        address mainCoin,
        uint256 refundPoolId,
        uint256[] calldata params
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
