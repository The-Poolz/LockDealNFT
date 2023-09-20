// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISimpleProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder is ERC721Holder {
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _nft) {
        lockDealNFT = _nft;
    }

    struct Builder {
        UserPool[] userPools;
        uint256 totalAmount;
    }

    struct UserPool {
        address user;
        uint256 amount;
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
    ) external {
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        ISimpleProvider provider = ISimpleProvider(addressParams[0]);
        address token = addressParams[1];
        uint256 length = userData.userPools.length;
        uint256 totalAmount = userData.totalAmount;
        require(totalAmount > 0, "invalid total amount");
        require(token != address(0x0), "invalid token address");
        require(length > 1, "invalid userPools length");
        // one time transfer for deacrease number transactions
        uint256 poolId = lockDealNFT.mintAndTransfer(
            userData.userPools[0].user,
            token,
            msg.sender,
            totalAmount,
            provider
        );
        provider.registerPool(poolId, _concatParams(userData.userPools[0].amount, params));
        totalAmount -= userData.userPools[0].amount;
        for (uint256 i = 1; i < length; ) {
            totalAmount -= _createNewNFT(provider, poolId, userData.userPools[i], params);
            unchecked {
                ++i;
            }
        }
        assert(totalAmount == 0);
    }

    function _createNewNFT(
        ISimpleProvider provider,
        uint256 tokenPoolId,
        UserPool calldata userData,
        uint256[] calldata params
    ) internal returns (uint256 amount) {
        amount = userData.amount;
        require(amount > 0, "invalid user amount");
        require(userData.user != address(0x0), "invalid user address");
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
