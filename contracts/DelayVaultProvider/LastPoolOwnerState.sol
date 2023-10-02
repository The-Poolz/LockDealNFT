// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IBeforeTransfer.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract LastPoolOwnerState is IBeforeTransfer, IERC165 {
    mapping(uint256 => address) internal LastPoolOwner;

    function beforeTransfer(address from, address to, uint256 poolId) external virtual override;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBeforeTransfer).interfaceId;
    }
}
