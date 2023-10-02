// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IBeforeTransfer.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../SimpleProviders/DealProvider/DealProviderState.sol";
import "../SimpleProviders/Provider/ProviderModifiers.sol";

abstract contract BeforeTransfer is IBeforeTransfer, IERC165, DealProviderState, ProviderModifiers {
    mapping(uint256 => address) internal LastPoolOwner;
    mapping(uint256 => uint8) internal PoolToType;
    mapping(address => uint256[]) public UserToTotalAmount; //thw array will be {typesCount} lentgh

    function beforeTransfer(address from, address to, uint256 poolId) external override {
        _beforeTransfer(from, to, poolId);
    }

    function _beforeTransfer(address from, address to, uint256 poolId) internal virtual {
        if (to == address(lockDealNFT))
            // this means it will be withdraw or split
            LastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        else {
            _handleTransfer(from, to, poolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal virtual returns (uint256 amount);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IBeforeTransfer).interfaceId;
    }
}
