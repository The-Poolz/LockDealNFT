// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IProvider.sol";
import "./RefundState.sol";

abstract contract RefundModifiers is RefundState {
    modifier validProviderInterface(IProvider provider, bytes4 interfaceId) {
        _validProviderInterface(provider, interfaceId);
        _;
    }
}
