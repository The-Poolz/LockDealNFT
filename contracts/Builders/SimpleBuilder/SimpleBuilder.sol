// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../Builder/BuilderInternal.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder is ERC721Holder, BuilderInternal {
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
        uint256[] memory params
    ) external validParamsLength(addressParams.length, 2) notZeroAddress(addressParams[1]) {
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(userData.userPools.length > 0, "invalid params length");
        uint256 totalAmount = userData.totalAmount;
        _notZeroAmount(totalAmount);
        address token = addressParams[1];
        ISimpleProvider provider = ISimpleProvider(addressParams[0]);
        UserPool calldata firstUserData = userData.userPools[0];
        uint256 length = userData.userPools.length;
        // one time transfer for deacrease number transactions
        params = _concatParams(firstUserData.amount, params);
        uint256 poolId;
        (poolId, totalAmount) = _createFirstNFT(provider, token, totalAmount, firstUserData, params);
        for (uint256 i = 1; i < length; ) {
            totalAmount -= _createNewNFT(provider, poolId, userData.userPools[i], params);
            unchecked {
                ++i;
            }
        }
        assert(totalAmount == 0);
    }
}
