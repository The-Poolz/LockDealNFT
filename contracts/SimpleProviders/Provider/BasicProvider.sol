// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderModifiers.sol";
import "../../interfaces/IProvider.sol";
import "../../interfaces/ISimpleProvider.sol";
import "../../ERC165/Refundble.sol";
import "../../ERC165/Bundable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BasicProvider is ProviderModifiers, ISimpleProvider, ERC165 {
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

    /**
     * @dev used by LockedDealNFT contract to withdraw tokens from a pool.
     * @param poolId The ID of the pool.
     * @return withdrawnAmount The amount of tokens withdrawn.
     * @return isFinal Boolean indicating whether the pool is empty after a withdrawal.
     */
    function withdraw(uint256 poolId) public virtual override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    /// @dev used by providers to implement cascading withdraw logic from the pool.
    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public virtual onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, amount);
    }

    function _registerPool(uint256 poolId, uint256[] calldata params) internal virtual;

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal virtual returns (uint256 withdrawnAmount, bool isFinal) {}

    function getWithdrawableAmount(uint256 poolId) public view virtual override returns (uint256);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == Refundble._INTERFACE_ID_Refundble ||
            interfaceId == Bundable._INTERFACE_ID_Bundable ||
            super.supportsInterface(interfaceId);
    }
}
