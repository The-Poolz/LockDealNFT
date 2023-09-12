// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../util/CalcUtils.sol";
import "hardhat/console.sol";

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

    struct UserSplit {
        address user;
        uint256 amount;
    }

    // address[0] = token
    // address[1] = mainCoin
    // address[2+] = provider
    // params[0][0-1] = collateral params, [0] start amount, [1] finish time
    // refund params - collateralId, generate. rate, calculate.
    // params[1+][0] - the sum need to be equal to the token amount (sum of userSplits)
    function buildRefundBundle(
        UserSplit[] memory userSplits,
        address[] calldata addressParams,
        uint256[][] calldata params
    ) public {
        //TODO require lenghts
        (uint256 poolId, uint256 tokenAmount) = _createRefundProvider(addressParams, params);
        if (!_splitToUsers(poolId, tokenAmount, userSplits)) {
            lockDealNFT.safeTransferFrom(address(this), msg.sender, poolId);
        }
    }

    function _splitToUsers(
        uint256 poolId,
        uint256 amount,
        UserSplit[] memory userSplits
    ) internal returns (bool isFinished) {
        uint256 splitLength = userSplits.length;
        for (uint256 i = 0; i < splitLength; ++i) {
            uint256 userAmount = userSplits[i].amount;
            address user = userSplits[i].user;
            uint256 ratio = userAmount.calcRate(amount);
            // By splitting, the user will receive refund pool, which in turn contains bundle, which in turn contains simple providers :)
            lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), poolId, abi.encode(ratio, user));
            // also by splitting every refund pool save collateral pool id that give opportunity to swap tokens to main coins
            amount -= userAmount;
        }
        isFinished = amount == 0;
    }

    function _createCollateralProvider(address mainCoin, uint256[] memory params) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, msg.sender, params[0], collateralProvider);
        collateralProvider.registerPool(poolId, params);
    }

    function _createRefundProvider(
        address[] calldata addressParams,
        uint256[][] calldata params
    ) internal returns (uint256 poolId, uint256 tokenAmount) {
        for (uint256 i = 1; i < params.length; i++) {
            tokenAmount += params[i][0];
        }
        address token = addressParams[0];
        address mainCoin = addressParams[1];
        uint256 mainCoinAmount = params[0][0];
        uint256[] memory collateralParams = params[0];
        // create collateral pool with main coin total amount for Project Owner (buildRefundBundle caller)
        uint256 collateralPoolId = _createCollateralProvider(mainCoin, collateralParams);
        uint256[] memory refundParams = new uint256[](2);
        refundParams[0] = collateralPoolId;
        refundParams[1] = mainCoinAmount.calcRate(tokenAmount);
        poolId = lockDealNFT.mintAndTransfer(address(this), token, msg.sender, tokenAmount, refundProvider);
        _createBundleProvider(addressParams, params);
        refundProvider.registerPool(poolId, refundParams);
    }

    function _createBundleProvider(
        address[] calldata addressParams,
        uint256[][] calldata params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(address(refundProvider), bundleProvider);
        for (uint256 i = 2; i < addressParams.length; ++i) {
            IProvider provider = IProvider(addressParams[i]);
            uint256 innerPoolId = lockDealNFT.mintForProvider(address(bundleProvider), provider);
            uint256[] memory innerParams = params[i - 1];
            provider.registerPool(innerPoolId, innerParams);
        }
        uint256[] memory bundleParams = new uint256[](1);
        bundleParams[0] = lockDealNFT.totalSupply() - 1;
        bundleProvider.registerPool(poolId, bundleParams);
    }
}
