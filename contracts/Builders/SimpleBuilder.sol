// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISimpleProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder {
    ILockDealNFT public lockDealNFT;

    constructor(ILockDealNFT _nft) {
        lockDealNFT = _nft;
    }

    struct UserPool {
        address user;
        uint256 amount;
    }

    /// @notice Build mass pools
    /// @param addressParams[0] - Provider address
    /// @param addressParams[1] - Token address
    /// @param userPools - Array of user pools
    /// @param params - Array of params. May be empty if this is DealProvider
    function buildMassPools(
        address[] calldata addressParams,
        UserPool[] calldata userPools,
        uint256[] calldata params
    ) external {
        uint256 length = userPools.length;
        require(
            ERC165Checker.supportsInterface(addressParams[0], type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        ISimpleProvider provider = ISimpleProvider(addressParams[0]);
        address token = addressParams[1];
        require(token != address(0x0), "invalid token address");
        require(length > 1, "invalid userPools length");
        uint256 totalAmount = _calcTotalAmount(userPools);
        // one time transfer for deacrease number transactions
        uint256 poolId = lockDealNFT.mintAndTransfer(address(lockDealNFT), token, msg.sender, totalAmount, provider);
        for (uint256 i = 0; i < length; ++i) {
            _createNewNFT(provider, poolId, userPools[i], params);
        }
    }

    function _createNewNFT(
        ISimpleProvider provider,
        uint256 tokenPoolId,
        UserPool calldata userData,
        uint256[] calldata params
    ) internal {
        require(userData.amount > 0, "invalid user amount");
        require(userData.user != address(0x0), "invalid user address");
        uint256 poolId = lockDealNFT.mintForProvider(userData.user, provider);
        provider.registerPool(poolId, _concatParams(userData.amount, params));
        lockDealNFT.copyVaultId(tokenPoolId, poolId);
    }

    function _calcTotalAmount(UserPool[] calldata userParams) internal pure returns (uint256 totalAmount) {
        uint256 length = userParams.length;
        for (uint256 i = 0; i < length; ++i) {
            totalAmount += userParams[i].amount;
        }
    }

    ///@dev if params is empty, then return [amount]
    function _concatParams(uint amount, uint256[] calldata params) internal pure returns (uint256[] memory result) {
        uint256 length = params.length;
        result = new uint256[](length + 1);
        result[0] = amount;
        for (uint256 i = 0; i < length; ++i) {
            result[i + 1] = params[i];
        }
    }
}
