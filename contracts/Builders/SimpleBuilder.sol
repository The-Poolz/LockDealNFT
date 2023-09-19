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
    function buildMassPools(
        ISimpleProvider provider,
        address token,
        UserPool[] calldata userPools,
        uint256[] calldata params
    ) external {
        uint256 length = userPools.length;
        require(
            ERC165Checker.supportsInterface(address(provider), type(ISimpleProvider).interfaceId),
            "invalid provider type"
        );
        require(token != address(0x0), "invalid token address");
        require(length > 1, "invalid userPools length");
        uint256 totalAmount = _calcTotalAmount(userPools);
        // one time transfer for deacrease number transactions
        uint256 poolId = lockDealNFT.mintAndTransfer(msg.sender, token, msg.sender, totalAmount, provider);
        for (uint256 i = 0; i < length; ++i) {
            uint256 userAmount = userPools[i].amount;
            address userAddress = userPools[i].user;
            require(userAmount > 0, "invalid user amount");
            require(userAddress != address(0x0), "invalid user address");
            uint256 userPoolId = lockDealNFT.mintForProvider(userAddress, provider);
            provider.registerPool(userPoolId, _concatParams(userAmount, params));
            lockDealNFT.copyVaultId(poolId, userPoolId);
        }
    }

    function _calcTotalAmount(UserPool[] calldata userParams) internal pure returns (uint256 totalAmount) {
        uint256 length = userParams.length;
        for (uint256 i = 0; i < length; ++i) {
            totalAmount += userParams[i].amount;
        }
    }

    function _concatParams(uint amount, uint256[] calldata params) internal pure returns (uint256[] memory result) {
        uint256 length = params.length;
        result = new uint256[](length + 1);
        result[0] = amount;
        for (uint256 i = 0; i < length; ++i) {
            result[i + 1] = params[i];
        }
    }
}
