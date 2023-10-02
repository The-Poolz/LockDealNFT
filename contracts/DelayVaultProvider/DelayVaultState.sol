// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProviderState.sol";
import "../SimpleProviders/Provider/ProviderModifiers.sol";
import "./LastPoolOwnerState.sol";

abstract contract DelayVaultState is DealProviderState, ProviderModifiers, LastPoolOwnerState {
    mapping(uint256 => uint8) internal PoolToType;
    mapping(address => uint256[]) public UserToTotalAmount; //thw array will be {typesCount} lentgh

    function _beforeTransfer(address from, address to, uint256 poolId) internal override {
        if (to == address(lockDealNFT))
            // this means it will be withdraw or split
            LastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        else {
            _handleTransfer(from, to, poolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal virtual returns (uint256 amount);
}
