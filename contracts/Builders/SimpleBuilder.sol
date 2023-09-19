// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISimpleProvider.sol";
import "../interfaces/ILockDealNFT.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @title SimpleBuilder contract
/// @notice This contract is used to create mass lock deals(NFTs)
contract SimpleBuilder {
    ILockDealNFT public lockDealNFT;
    ISimpleProvider dealProvider; // for project owner

    constructor(ILockDealNFT _nft) {
        lockDealNFT = _nft;
    }

    struct UserPool {
        address user;
        uint256[] params;
    }

    /// @notice Build mass pools
    /// @param provider The provider address
    function buildMassPools(ISimpleProvider provider, address token, UserPool[] memory userPools) external {
        uint256 length = userPools.length;
        uint256 totalAmount = _calcTotalAmount(provider, userPools);
        require(
            ERC165Checker.supportsInterface(address(provider), type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(token != address(0x0), "invalid token address");
        require(length > 1, "invalid userPools length");
        // one time transfer for deacrease number transactions
        uint256 poolId = lockDealNFT.mintAndTransfer(userPools[0].user, token, msg.sender, totalAmount, provider);
        // regiter default values for first pool
        provider.registerPool(poolId, userPools[0].params);
        for (uint256 i = 1; i < length; ++i) {
            uint256 userPoolId = lockDealNFT.mintForProvider(userPools[i].user, provider);
            provider.registerPool(userPoolId, userPools[i].params);
            lockDealNFT.copyVaultId(poolId, userPoolId);
        }
    }

    function _calcTotalAmount(
        ISimpleProvider provider,
        UserPool[] memory userParams
    ) internal view returns (uint256 totalAmount) {
        uint256 length = userParams.length;
        uint256 minLength = provider.currentParamsTargetLenght();
        for (uint256 i = 0; i < length; ++i) {
            uint256[] memory params = userParams[i].params;
            require(params.length == minLength, "invalid params length");
            totalAmount += params[0];
        }
    }
}
