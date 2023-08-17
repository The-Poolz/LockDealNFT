// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../../interfaces/IProvider.sol";

contract RefundModifiers {
    modifier validProviderInterface(IProvider provider, bytes4 interfaceId) {
        _validProviderInterface(provider, interfaceId);
        _;
    }

    function _validProviderInterface(IProvider provider, bytes4 interfaceId) internal view {
        require(ERC165Checker.supportsInterface(address(provider), interfaceId), "invalid provider type");
    }
}
