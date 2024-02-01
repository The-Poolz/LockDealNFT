// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IFeeProvider.sol";

contract FeeProvider is IFeeProvider, ERC165 {
    bool public constant feeProvider = true;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFeeProvider).interfaceId || super.supportsInterface(interfaceId);
    }
}
