// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderModifiers.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IProvider.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ISimpleProvider.sol";
import "../../ERC165/Refundble.sol";
import "../../ERC165/Bundable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@ironblocks/firewall-consumer/contracts/FirewallConsumer.sol";

abstract contract BasicProvider is ProviderModifiers, ISimpleProvider, ERC165, FirewallConsumer {
    /**
     * @dev Creates a new pool with the specified parameters.
     * @param addresses[0] The address of the pool owner.
     * @param addresses[1] The address of the token associated with the pool.
     * @param params An array of pool parameters.
     * @param signature The signature of the pool owner.
     * @return poolId The ID of the newly created pool.
     */
    function createNewPool(
        address[] calldata addresses,
        uint256[] calldata params,
        bytes calldata signature
    )
        external
        virtual
        firewallProtected
        validAddressesLength(addresses.length, 2)
        validParamsLength(params.length, currentParamsTargetLength())
        returns (uint256 poolId)
    {
        poolId = lockDealNFT.safeMintAndTransfer(addresses[0], addresses[1], msg.sender, params[0], this, signature);
        _registerPool(poolId, params);
    }

    /// @dev used by providers to implement cascading pool creation logic.
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) external virtual firewallProtected onlyProvider validParamsLength(params.length, currentParamsTargetLength()) {
        _registerPool(poolId, params);
    }

    /**
     * @dev used by LockedDealNFT contract to withdraw tokens from a pool.
     * @param poolId The ID of the pool.
     * @return withdrawnAmount The amount of tokens withdrawn.
     * @return isFinal Boolean indicating whether the pool is empty after a withdrawal.
     */
    function withdraw(uint256 poolId) external virtual firewallProtected override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    /// @dev used by providers to implement cascading withdraw logic from the pool.
    function withdraw(
        uint256 poolId,
        uint256 amount
    ) external virtual firewallProtected onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
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
            interfaceId == Refundble._INTERFACE_ID_REFUNDABLE ||
            interfaceId == Bundable._INTERFACE_ID_BUNDABLE ||
            interfaceId == type(ISimpleProvider).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Executes before a transfer, updating state based on the transfer details.
     * @param from Sender address.
     * @param to Receiver address.
     * @param poolId Pool identifier.
     */
    function beforeTransfer(
        address from,
        address to,
        uint256 poolId
    ) external virtual override firewallProtected onlyNFT {
        if (to == address(lockDealNFT)) {
            // this means it will be withdraw or split
            lastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        }
    }
}
