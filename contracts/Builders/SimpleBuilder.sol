// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISimpleProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./BuilderModifiers.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder is ERC721Holder, BuilderModifiers {
    constructor(ILockDealNFT _nft) {
        lockDealNFT = _nft;
    }

    /// @notice Build mass pools
    /// @param addressParams[0] - Provider address
    /// @param addressParams[1] - Token address
    /// @param userData - Array of user pools
    /// @param params - Array of params. May be empty if this is DealProvider
    function buildMassPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[] calldata params
    )
        external
        validParamsLength(addressParams.length, 2)
        validProviderInterface(addressParams[0], type(ISimpleProvider).interfaceId)
        validParamsLength(userData.userPools.length, 1)
        notZeroAmount(userData.totalAmount)
        notZeroAddress(addressParams[1])
    {
        ISimpleProvider provider = ISimpleProvider(addressParams[0]);
        address token = addressParams[1];
        uint256 length = userData.userPools.length;
        uint256 totalAmount = userData.totalAmount;
        // one time transfer for deacrease number transactions
        (uint256 poolId, uint256 amount) = _createFirstNFT(provider, token, totalAmount, userData.userPools[0], params);
        totalAmount -= amount;
        for (uint256 i = 1; i < length; ) {
            totalAmount -= _createNewNFT(provider, poolId, userData.userPools[i], params);
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
        uint256[] calldata params
    ) internal validUserData(userData) returns (uint256 poolId, uint256 amount) {
        poolId = lockDealNFT.mintAndTransfer(userData.user, token, msg.sender, totalAmount, provider);
        provider.registerPool(poolId, _concatParams(userData.amount, params));
        amount = userData.amount;
    }

    function _createNewNFT(
        ISimpleProvider provider,
        uint256 tokenPoolId,
        UserPool calldata userData,
        uint256[] calldata params
    ) internal validUserData(userData) returns (uint256 amount) {
        amount = userData.amount;
        uint256 poolId = lockDealNFT.mintForProvider(userData.user, provider);
        provider.registerPool(poolId, _concatParams(amount, params));
        lockDealNFT.copyVaultId(tokenPoolId, poolId);
    }

    ///@dev if params is empty, then return [amount]
    function _concatParams(uint amount, uint256[] calldata params) internal pure returns (uint256[] memory result) {
        uint256 length = params.length;
        result = new uint256[](length + 1);
        result[0] = amount;
        for (uint256 i = 0; i < length; ) {
            result[i + 1] = params[i];
            unchecked {
                ++i;
            }
        }
    }
}
