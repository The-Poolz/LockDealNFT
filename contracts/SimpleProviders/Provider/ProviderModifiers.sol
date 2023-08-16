// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderState.sol";

abstract contract ProviderModifiers is ProviderState {
    modifier onlyProvider() {
        _onlyProvider();
        _;
    }

    modifier validParamsLength(uint256 paramsLength, uint256 minLength) {
        _validParamsLength(paramsLength, minLength);
        _;
    }

    modifier onlyNFT() {
        _onlyNFT();
        _;
    }

    modifier validProviderId(uint256 poolId) {
        _validProvider(poolId);
        _;
    }

    function _validProvider(uint256 poolId) internal view {
        require(lockDealNFT.poolIdToProvider(poolId) == this, "Invalid provider poolId");
    }

    function _onlyNFT() internal view {
        require(msg.sender == address(lockDealNFT), "only NFT contract can call this function");
    }

    function _validParamsLength(uint256 paramsLength, uint256 minLength) private pure {
        require(paramsLength >= minLength, "invalid params length");
    }

    function _onlyProvider() private view {
        require(lockDealNFT.approvedProviders(msg.sender), "invalid provider address");
    }
}
