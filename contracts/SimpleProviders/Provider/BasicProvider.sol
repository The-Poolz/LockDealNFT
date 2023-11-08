// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderModifiers.sol";
import "../../interfaces/IProvider.sol";
import "../../interfaces/ISimpleProvider.sol";
import "../../ERC165/Refundble.sol";
import "../../ERC165/Bundable.sol";
import "@spherex-xyz/openzeppelin-solidity/contracts/utils/introspection/ERC165.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
import {ModifierLocals} from "@spherex-xyz/contracts/src/ISphereXEngine.sol";

 

abstract contract BasicProvider is ProviderModifiers, ISimpleProvider, ERC165 , SphereXProtected {
    modifier sphereXGuardPublic_createNewPool() {
        ModifierLocals memory locals = _sphereXValidatePre(0x394c07d0, msg.sig == 0x14877c38);
        _;
        _sphereXValidatePost(-0x394c07d0, msg.sig == 0x14877c38, locals);
    }

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
        public
        virtual
        validAddressesLength(addresses.length, 2)
        validParamsLength(params.length, currentParamsTargetLenght())
        sphereXGuardPublic_createNewPool returns (uint256 poolId)
    {
        poolId = lockDealNFT.safeMintAndTransfer(addresses[0], addresses[1], msg.sender, params[0], this, signature);
        _registerPool(poolId, params);
    }

    /// @dev used by providers to implement cascading pool creation logic.
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) public virtual onlyProvider validParamsLength(params.length, currentParamsTargetLenght()) sphereXGuardPublic(0x65019c70, 0xe9a9fce2) {
        _registerPool(poolId, params);
    }

    /**
     * @dev used by LockedDealNFT contract to withdraw tokens from a pool.
     * @param poolId The ID of the pool.
     * @return withdrawnAmount The amount of tokens withdrawn.
     * @return isFinal Boolean indicating whether the pool is empty after a withdrawal.
     */
    function withdraw(uint256 poolId) public virtual override onlyNFT sphereXGuardPublic(0x3ff12ca0, 0x2e1a7d4d) returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    /// @dev used by providers to implement cascading withdraw logic from the pool.
    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public virtual onlyProvider sphereXGuardPublic(0x08e30c21, 0x441a3e70) returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, amount);
    }

    function _registerPool(uint256 poolId, uint256[] calldata params) internal virtual;

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal virtual sphereXGuardInternal(0x2b279427) returns (uint256 withdrawnAmount, bool isFinal) {}

    function getWithdrawableAmount(uint256 poolId) public view virtual override returns (uint256);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == Refundble._INTERFACE_ID_REFUNDABLE ||
            interfaceId == Bundable._INTERFACE_ID_BUNDABLE ||
            interfaceId == type(ISimpleProvider).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
