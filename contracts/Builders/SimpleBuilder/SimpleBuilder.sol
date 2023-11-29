// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../Builder/BuilderInternal.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder is ERC721Holder, BuilderInternal, FirewallConsumer {
    constructor(ILockDealNFT _nft) {
        lockDealNFT = _nft;
    }

    struct MassPoolsLocals {
        uint256 totalAmount;
        address token;
        ISimpleProvider provider;
        uint256 length;
        uint256 poolId;
    }

    /// @notice Build mass pools
    /// @param addressParams[0] - Provider address
    /// @param addressParams[1] - Token address
    /// @param userData - Array of user pools
    /// @param params - Array of params. May be empty if this is DealProvider
    function buildMassPools(
        address[] calldata addressParams,
        Builder calldata userData,
        uint256[] calldata params,
        bytes calldata signature
    ) external firewallProtected notZeroAddress(addressParams[1]) {
        _validParamsLength(addressParams.length, 2);
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(userData.userPools.length > 0, "invalid user length");
        MassPoolsLocals memory locals;
        locals.totalAmount = userData.totalAmount;
        _notZeroAmount(locals.totalAmount);
        locals.token = addressParams[1];
        locals.provider = ISimpleProvider(addressParams[0]);
        UserPool calldata firstUserData = userData.userPools[0];
        locals.length = userData.userPools.length;
        // one time transfer for deacrease number transactions
        uint256[] memory simpleParams = _concatParams(firstUserData.amount, params);
        locals.poolId = _createFirstNFT(locals.provider, locals.token, firstUserData.user, locals.totalAmount, simpleParams, signature);
        locals.totalAmount -= firstUserData.amount;
        for (uint256 i = 1; i < locals.length; ) {
            UserPool calldata userPool = userData.userPools[i];
            locals.totalAmount -= _createNewNFT(locals.provider, locals.poolId, userPool, simpleParams);
            unchecked {
                ++i;
            }
        }
        assert(locals.totalAmount == 0);
    }
}
