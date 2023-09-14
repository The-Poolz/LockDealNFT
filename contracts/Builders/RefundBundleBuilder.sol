// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../util/CalcUtils.sol";

/// @title RefundBundleBuilder contract
/// @notice Implements a contract for building refund bundles
contract RefundBundleBuilder is ERC721Holder {
    using CalcUtils for uint256;
    ILockDealNFT public lockDealNFT;
    IProvider public refundProvider;
    IProvider public bundleProvider;
    IProvider public collateralProvider;

    constructor(ILockDealNFT _nft, IProvider _refund, IProvider _bundle, IProvider _collateral) {
        lockDealNFT = _nft;
        refundProvider = _refund;
        bundleProvider = _bundle;
        collateralProvider = _collateral;
    }

    struct UserPool {
        address user;
        uint256 amount;
    }

    // address[0] = token
    // address[1] = mainCoin
    // address[2+] = provider
    // params[0][0-1] = collateral params, [0] start amount, [1] finish time
    // refund params - collateralId, generate. rate, calculate.
    // params[1+][0] - the sum need to be equal to the token amount (sum of userPools)
    function buildRefundBundle(
        UserPool[] memory userPools,
        address[] calldata addressParams,
        uint256[][] calldata params
    ) public {
        //TODO require lenghts
        uint256 firstRefundPoolId = lockDealNFT.totalSupply();
        uint256 lastRefundPoolId = _createRefundPools(addressParams, params, userPools);
        address mainCoin = addressParams[1];
        uint256 collateralPoolId = _createCollateralProvider(mainCoin, lastRefundPoolId, params[0]);
        // register refund pools
        _registerRefundPools(
            collateralPoolId,
            firstRefundPoolId,
            lastRefundPoolId,
            addressParams.length - 2,
            userPools
        );
    }

    function _createRefundPools(
        address[] calldata addressParams,
        uint256[][] calldata params,
        UserPool[] memory userPools
    ) internal returns (uint256 lastPoolId) {
        address token = addressParams[0];
        uint256 length = userPools.length - 1;
        uint256 userAmount;
        address user;
        for (uint256 i = 0; i < length; ++i) {
            userAmount = userPools[i].amount;
            user = userPools[i].user;
            // mint refund pools for users
            lockDealNFT.mintAndTransfer(user, token, msg.sender, userAmount, refundProvider);
            _createBundleProvider(addressParams, params);
        }
        userAmount = userPools[length].amount;
        user = userPools[length].user;
        lastPoolId = lockDealNFT.mintAndTransfer(user, token, msg.sender, userAmount, refundProvider);
        _createBundleProvider(addressParams, params);
    }

    function _createBundleProvider(address[] calldata addressParams, uint256[][] calldata params) internal {
        uint256 poolId = lockDealNFT.mintForProvider(address(refundProvider), bundleProvider);
        for (uint256 i = 2; i < addressParams.length; ++i) {
            IProvider provider = IProvider(addressParams[i - 1]);
            uint256 innerPoolId = lockDealNFT.mintForProvider(address(bundleProvider), provider);
            uint256[] memory innerParams = params[i - 1];
            provider.registerPool(innerPoolId, innerParams);
        }
        uint256[] memory bundleParams = new uint256[](1);
        bundleParams[0] = lockDealNFT.totalSupply() - 1;
        bundleProvider.registerPool(poolId, bundleParams);
    }

    function _registerRefundPools(
        uint256 collateralPoolId,
        uint256 firstRefundPoolId,
        uint256 lastRefundPoolId,
        uint256 bundleLength,
        UserPool[] memory userPools
    ) internal {
        for (uint256 i = 0; i < lastRefundPoolId; i += bundleLength) {
            // uint256[] memory refundParams = new uint256[](2);
            // refundParams[0] = collateralPoolId;
            // refundParams[1] = 1;
            // refundProvider.registerPool(i, refundParams);
        }
    }

    function _createToUsers(
        uint256 poolId,
        uint256 amount,
        UserPool[] memory userPools
    ) internal returns (bool isFinished) {
        uint256 poolsLength = userPools.length;
        for (uint256 i = 0; i < poolsLength; ++i) {
            uint256 userAmount = userPools[i].amount;
            address user = userPools[i].user;

            //uint256 ratio = userAmount.calcRate(amount);
            // By splitting, the user will receive refund pool, which in turn contains bundle, which in turn contains simple providers :)
            //lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId, abi.encode(ratio, user));
            // also by splitting every refund pool save collateral pool id that give opportunity to swap tokens to main coins
            amount -= userAmount;
        }
        isFinished = amount == 0;
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

    function registerRefundPools() internal {}

    // function _createRefundProvider(
    //     address[] calldata addressParams,
    //     uint256[][] calldata params
    // ) internal returns (uint256 poolId, uint256 tokenAmount) {
    //     uint256 length = params.length;
    //     for (uint256 i = 1; i < length; ++i) {
    //         tokenAmount += params[i][0];
    //     }
    //     address token = addressParams[0];
    //     address mainCoin = addressParams[1];
    //     uint256 mainCoinAmount = params[0][0];
    //     uint256[] memory collateralParams = params[0];
    //     poolId = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, tokenAmount, refundProvider);
    //     _createBundleProvider(addressParams, params);
    //     // create collateral pool with main coin total amount for Project Owner (buildRefundBundle caller)
    //     uint256 collateralPoolId = _createCollateralProvider(mainCoin, poolId, collateralParams);
    //     // uint256[] memory refundParams = new uint256[](2);
    //     // refundParams[0] = collateralPoolId;
    //     // refundParams[1] = mainCoinAmount.calcRate(tokenAmount);
    //     // refundProvider.registerPool(poolId, refundParams);
    // }

    // function _createBundleProvider(address[] calldata addressParams, uint256[][] calldata params) internal {
    //     uint256 poolId = lockDealNFT.mintForProvider(address(refundProvider), bundleProvider);
    //     for (uint256 i = 2; i < addressParams.length; ++i) {
    //         IProvider provider = IProvider(addressParams[i]);
    //         uint256 innerPoolId = lockDealNFT.mintForProvider(address(bundleProvider), provider);
    //         uint256[] memory innerParams = params[i - 1];
    //         provider.registerPool(innerPoolId, innerParams);
    //     }
    //     uint256[] memory bundleParams = new uint256[](1);
    //     bundleParams[0] = lockDealNFT.totalSupply() - 1;
    //     bundleProvider.registerPool(poolId, bundleParams);
    // }
}
