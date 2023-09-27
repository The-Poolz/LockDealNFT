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
        uint256 totalAmount = userData.totalAmount;
        require(totalAmount > 0, "invalid totalAmount");
        address token = addressParams[0];
        ISimpleProvider provider = ISimpleProvider(addressParams[2]);
        // one time transfer for deacrease number transactions
        uint256 poolId;
        (poolId, totalAmount) = _createFirstNFT(provider, token, totalAmount, userData.userPools[0], params[0]);
        address mainCoin = addressParams[1];
        uint256 mainCoinAmount = params[0][0];
        uint256 length = userData.userPools.length;
        uint256[] memory refundParams = new uint256[](2);
        refundParams[0] = _createCollateralProvider(mainCoin, poolId, params[0]);
        refundParams[1] = mainCoinAmount.calcRate(userData.totalAmount);
        refundProvider.registerPool(poolId, refundParams);
        for (uint256 i = 1; i < length; ) {
            uint256 userAmount = userData.userPools[i].amount;
            address user = userData.userPools[i].user;
            // mint refund pools for users
            uint256[] memory simpleParams = params[1];
            lockDealNFT.mintForProvider(user, refundProvider);
            totalAmount -= _createNewNFT(provider, poolId, UserPool(address(refundProvider), userAmount), simpleParams);
            refundProvider.registerPool(i, refundParams);
            unchecked {
                ++i;
            }
        }
        assert(totalAmount == 0);
    }

    function _createFirstNFT(
        ISimpleProvider provider,
        address token,
        uint256 totalAmount,
        UserPool calldata userData,
        uint256[] memory params
    ) internal virtual override validUserData(userData) returns (uint256 poolId, uint256 amount) {
        poolId = lockDealNFT.mintAndTransfer(userData.user, token, msg.sender, totalAmount, refundProvider);
        params = _concatParams(userData.amount, params);
        totalAmount -= _createNewNFT(provider, poolId, UserPool(address(refundProvider), userData.amount), params);
        amount = totalAmount - userData.amount;
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
}
