// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderModifiers.sol";
import "../ProviderInterface/IProvider.sol";

abstract contract BasicProvider is IProvider, ProviderModifiers {
    ///@dev requirements are in mint, _register functions
    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public virtual returns (uint256 poolId) {
        poolId = lockDealNFT.mint(owner, token, msg.sender, params[0]);
        _registerPool(poolId, owner, token, params);
    }

    function registerPool(
        uint256 poolId,
        address owner,
        address token,
        uint256[] memory params
    ) public virtual onlyProvider {
        _registerPool(poolId, owner, token, params);
    }

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
        address owner,
        address token,
        uint256[] memory params
    ) internal virtual {}

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal virtual returns (uint256 withdrawnAmount, bool isFinal) {}
}
