// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderModifiers.sol";
import "../../interfaces/IProvider.sol";

abstract contract BasicProvider is IProvider, ProviderModifiers {
    /**
     * @dev Creates a new pool with the specified parameters.
     * @param owner The address of the pool owner.
     * @param token The address of the token associated with the pool.
     * @param params An array of pool parameters.
     * @return poolId The ID of the newly created pool.
     */
    function createNewPool(
        address owner,
        address token,
        uint256[] calldata params
    ) public virtual validParamsLength(params.length, currentParamsTargetLenght()) returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, params[0], this);
        _registerPool(poolId, params);
    }

    
    /// @dev used by providers to implement cascading pool creation logic.
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) public virtual onlyProvider validParamsLength(params.length, currentParamsTargetLenght()) {
        _registerPool(poolId, params);
    }

    /// @dev used by providers to implement cascading withdraw logic from the pool.
    function withdraw(
        uint256 poolId,
        uint256 amount
    )
        public
        virtual
        onlyProvider
        returns (uint256 withdrawnAmount, bool isFinal)
    {
        (withdrawnAmount, isFinal) = _withdraw(poolId, amount);
    }

    function _registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) internal virtual {}

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal virtual returns (uint256 withdrawnAmount, bool isFinal) {}
}
