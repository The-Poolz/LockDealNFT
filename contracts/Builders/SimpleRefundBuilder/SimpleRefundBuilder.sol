// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../../interfaces/ISimpleProvider.sol";
import "../Builder/BuilderInternal.sol";
import "../../util/CalcUtils.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

/// @title SimpleRefundBuilder contract
/// @notice Implements a contract for building refund simple providers
contract SimpleRefundBuilder is ERC721Holder, BuilderInternal, FirewallConsumer {
    using CalcUtils for uint256;
    IProvider public refundProvider;
    IProvider public collateralProvider;

    constructor(ILockDealNFT _nft, IProvider _refund, IProvider _collateral) {
        lockDealNFT = _nft;
        refundProvider = _refund;
        collateralProvider = _collateral;
    }

    struct ParamsData {
        ISimpleProvider provider;
        address token;
        address mainCoin;
        uint256 mainCoinAmount;
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
        uint256[][] calldata params,
        bytes calldata tokenSignature,
        bytes calldata mainCoinSignature
    ) external firewallProtected {
        ParamsData memory paramsData = _validateParamsData(addressParams, params);
        require(userData.userPools.length > 0, "invalid user length");
        uint256 totalAmount = userData.totalAmount;
        require(totalAmount > 0, "invalid totalAmount");
        uint256[] memory simpleParams = _concatParams(userData.userPools[0].amount, params[1]);
        uint256 poolId = _createFirstNFT(
            paramsData.provider,
            paramsData.token,
            userData.userPools[0].user,
            totalAmount,
            simpleParams,
            tokenSignature
        );
        uint256[] memory refundParams = _finalizeFirstNFT(
            poolId - 1,
            paramsData.mainCoin,
            totalAmount,
            paramsData.mainCoinAmount,
            params[0][1],
            mainCoinSignature
        );
        _userDataIterator(paramsData.provider, userData.userPools, totalAmount, poolId, simpleParams, refundParams);
    }

    function _createFirstNFT(
        ISimpleProvider provider,
        address token,
        address owner,
        uint256 totalAmount,
        uint256[] memory params,
        bytes calldata signature
    ) internal virtual override firewallProtectedSig(0x29454335) returns (uint256 poolId) {
        // one time token transfer for deacrease number transactions
        lockDealNFT.mintForProvider(owner, refundProvider);
        poolId = super._createFirstNFT(provider, token, address(refundProvider), totalAmount, params, signature);
    }

    function _createCollateralProvider(
        address mainCoin,
        uint256 tokenPoolId,
        uint256 totalAmount,
        uint256 mainCoinAmount,
        uint256 collateralFinishTime,
        bytes calldata signature
    ) internal firewallProtectedSig(0x4516d406) returns (uint256 poolId) {
        poolId = lockDealNFT.safeMintAndTransfer(
            msg.sender,
            mainCoin,
            msg.sender,
            mainCoinAmount,
            collateralProvider,
            signature
        );
        uint256[] memory collateralParams = new uint256[](3);
        collateralParams[0] = totalAmount;
        collateralParams[1] = mainCoinAmount;
        collateralParams[2] = collateralFinishTime;
        collateralProvider.registerPool(poolId, collateralParams);
        lockDealNFT.cloneVaultId(poolId + 2, tokenPoolId);
    }

    function _validateParamsData(
        address[] calldata addressParams,
        uint256[][] calldata params
    ) internal view returns (ParamsData memory paramsData) {
        require(addressParams.length == 3, "invalid addressParams length");
        require(params.length == 2, "invalid params length");
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(addressParams[0] != address(0), "invalid provider address");
        require(addressParams[1] != address(0), "invalid token address");
        require(addressParams[2] != address(0), "invalid mainCoin address");
        paramsData.token = addressParams[1];
        paramsData.provider = ISimpleProvider(addressParams[0]);
        paramsData.mainCoin = addressParams[2];
        paramsData.mainCoinAmount = params[0][0];
    }

    function _finalizeFirstNFT(
        uint256 poolId,
        address mainCoin,
        uint256 totalAmount,
        uint256 mainCoinAmount,
        uint256 collateralFinishTime,
        bytes calldata signature
    ) internal firewallProtectedSig(0xcfc2dc78) returns (uint256[] memory refundParams) {
        refundParams = new uint256[](1);
        refundParams[0] = _createCollateralProvider(
            mainCoin,
            poolId,
            totalAmount,
            mainCoinAmount,
            collateralFinishTime,
            signature
        );
        refundProvider.registerPool(poolId, refundParams);
    }

    function _userDataIterator(
        ISimpleProvider provider,
        UserPool[] calldata userData,
        uint256 totalAmount,
        uint256 tokenPoolId,
        uint256[] memory simpleParams,
        uint256[] memory refundParams
    ) internal firewallProtectedSig(0xbbc1f709) {
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
