// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../../interfaces/ISimpleProvider.sol";
import "../Builder/BuilderInternal.sol";
import "../../util/CalcUtils.sol";
import "hardhat/console.sol";

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

    /// @param addressParams[0] = simpleProvider
    /// @param addressParams[1] = token
    /// @param addressParams[2] = mainCoin
    /// @param userData - array of user pools
    /// @param params[0] = collateral params, [0] start amount, [1] finish time
    /// @param params[1] = Array of params for simpleProvider. May be empty if this is DealProvider
    function buildMassPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[][] calldata params
    ) public {
        (ISimpleProvider provider, address token, address mainCoin, uint256 mainCoinAmount) = _validateParamsData(
            addressParams,
            params
        );
        require(userData.userPools.length > 0, "invalid user length");
        uint256 totalAmount = userData.totalAmount;
        require(totalAmount > 0, "invalid totalAmount");
        uint256[] memory simpleParams = _concatParams(userData.userPools[0].amount, params[1]);
        uint256 poolId = _createFirstNFT(provider, token, userData.userPools[0].user, totalAmount, simpleParams);
        uint256[] memory refundParams = _finalizeFirstNFT(poolId - 1, mainCoin, totalAmount, mainCoinAmount, params[0]);
        _userDataIterator(provider, userData.userPools, totalAmount, poolId, simpleParams, refundParams);
    }

    function _createFirstNFT(
        ISimpleProvider provider,
        address token,
        address owner,
        uint256 totalAmount,
        uint256[] memory params
    ) internal virtual override returns (uint256 poolId) {
        // one time token transfer for deacrease number transactions
        lockDealNFT.mintForProvider(owner, refundProvider);
        poolId = super._createFirstNFT(provider, token, address(refundProvider), totalAmount, params);
    }

    function _createCollateralProvider(
        address mainCoin,
        uint256 tokenPoolId,
        uint256 totalAmount,
        uint256 mainCoinAmount,
        uint256[] memory params
    ) internal returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(msg.sender, mainCoin, msg.sender, params[0], collateralProvider);
        uint256[] memory collateralParams = new uint256[](4);
        collateralParams[0] = params[0];
        collateralParams[1] = params[1];
        collateralParams[2] = mainCoinAmount.calcRate(totalAmount);
        collateralParams[3] = tokenPoolId;
        collateralProvider.registerPool(poolId, collateralParams);
    }

    function _validateParamsData(
        address[] calldata addressParams,
        uint256[][] calldata params
    ) internal view returns (ISimpleProvider provider, address token, address mainCoin, uint256 mainCoinAmount) {
        require(addressParams.length == 3, "invalid addressParams length");
        require(params.length == 2, "invalid params length");
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(addressParams[0] != address(0), "invalid provider address");
        require(addressParams[1] != address(0), "invalid token address");
        require(addressParams[2] != address(0), "invalid mainCoin address");
        token = addressParams[1];
        provider = ISimpleProvider(addressParams[0]);
        mainCoin = addressParams[2];
        mainCoinAmount = params[0][0];
    }

    function _finalizeFirstNFT(
        uint256 poolId,
        address mainCoin,
        uint256 totalAmount,
        uint256 mainCoinAmount,
        uint256[] memory collateralParams
    ) internal returns (uint256[] memory refundParams) {
        refundParams = new uint256[](2);
        refundParams[0] = _createCollateralProvider(mainCoin, poolId, totalAmount, mainCoinAmount, collateralParams);
        refundProvider.registerPool(poolId, refundParams);
    }

    function _userDataIterator(
        ISimpleProvider provider,
        UserPool[] calldata userData,
        uint256 totalAmount,
        uint256 tokenPoolId,
        uint256[] memory simpleParams,
        uint256[] memory refundParams
    ) internal {
        uint256 length = userData.length;
        require(length > 0, "invalid userPools length");
        totalAmount -= userData[0].amount;
        // create refund pools for users
        for (uint256 i = 1; i < length; ) {
            uint256 userAmount = userData[i].amount;
            address user = userData[i].user;
            uint256 refundPoolId = lockDealNFT.mintForProvider(user, refundProvider);
            totalAmount -= _createNewNFT(
                provider,
                tokenPoolId,
                UserPool(address(refundProvider), userAmount),
                simpleParams
            );
            refundProvider.registerPool(refundPoolId, refundParams);
            unchecked {
                ++i;
            }
        }
        // check that all tokens are distributed correctly
        assert(totalAmount == 0);
    }
}
