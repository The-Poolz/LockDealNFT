// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderState.sol";
import "@spherex-xyz/openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";

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

    modifier validProviderAssociation(uint256 poolId, IProvider provider) {
        _validProvider(poolId, provider);
        _;
    }

    modifier validProviderId(uint256 poolId) {
        _validProvider(poolId, this);
        _;
    }

    modifier validAddressesLength(uint256 addressLength, uint256 minLength) {
        _validAddressLength(addressLength, minLength);
        _;
    }

    function _validAddressLength(uint256 addressLength, uint256 minLength) internal pure {
        require(addressLength >= minLength, "invalid addresses length");
    }

    function _validProvider(uint256 poolId, IProvider provider) internal view {
        require(lockDealNFT.poolIdToProvider(poolId) == provider, "Invalid provider poolId");
    }

    function _onlyNFT() internal view {
        require(msg.sender == address(lockDealNFT), "only NFT contract can call this function");
    }

    function _validParamsLength(uint256 paramsLength, uint256 minLength) private pure {
        require(paramsLength >= minLength, "invalid params length");
    }

    function _onlyProvider() private view {
        require(lockDealNFT.approvedContracts(msg.sender), "invalid provider address");
    }

    function _validProviderInterface(IProvider provider, bytes4 interfaceId) internal view {
        require(ERC165Checker.supportsInterface(address(provider), interfaceId), "invalid provider type");
    }
}
