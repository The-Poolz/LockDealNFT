// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BuilderModifiers.sol";
import "../../interfaces/ISimpleProvider.sol";

contract BuilderInternal is BuilderModifiers {
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

    function _createNewNFT(
        ISimpleProvider provider,
        uint256 tokenPoolId,
        UserPool memory userData,
        uint256[] memory params
    ) internal virtual validUserData(userData) returns (uint256 amount) {
        amount = userData.amount;
        uint256 poolId = lockDealNFT.mintForProvider(userData.user, provider);
        params[0] = userData.amount;
        provider.registerPool(poolId, params);
        lockDealNFT.copyVaultId(tokenPoolId, poolId);
    }

    function _createFirstNFT(
        ISimpleProvider provider,
        address token,
        address owner,
        uint256 totalAmount,
        uint256[] memory params
    ) internal virtual notZeroAddress(owner) returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, totalAmount, provider);
        provider.registerPool(poolId, params);
    }
}
