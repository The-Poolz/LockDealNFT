// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BuilderModifiers.sol";
import "../../interfaces/ISimpleProvider.sol";

contract BuilderInternal is BuilderModifiers {
    ///@dev if params is empty, then return [amount]
    function _concatParams(uint amount, uint256[] memory params) internal pure returns (uint256[] memory result) {
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
        address owner,
        uint256 amount,
        uint256[] memory params
    ) internal notZeroAddress(owner) notZeroAmount(amount) returns (uint256) {
        uint256 poolId = lockDealNFT.mintForProvider(owner, provider);
        params[0] = amount;
        provider.registerPool(poolId, params);
        lockDealNFT.copyVaultId(tokenPoolId, poolId);
        return amount;
    }
}
