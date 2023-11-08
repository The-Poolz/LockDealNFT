// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@spherex-xyz/openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";
import "../../interfaces/IProvider.sol";
import "../../ERC165/Bundable.sol";
import "./BundleProviderState.sol";

abstract contract BundleModifiers is BundleProviderState {
    modifier validBundleParams(uint256 poolId, uint256 lastSubPoolId) {
        _validBundleParams(poolId, lastSubPoolId);
        _;
    }

    modifier validProviderInterface(IProvider provider, bytes4 interfaceId) {
        _validProviderInterface(provider, interfaceId);
        _;
    }

    modifier validLastPoolId(uint256 poolId, uint256 lastSubPoolId) {
        _validLastPoolId(poolId, lastSubPoolId);
        _;
    }

    function _validLastPoolId(uint256 poolId, uint256 lastSubPoolId) internal pure {
        require(poolId < lastSubPoolId, "poolId can't be greater than lastSubPoolId");
    }

    function _validBundleParams(uint256 poolId, uint256 lastSubPoolId) internal view {
        for (uint256 i = poolId + 1; i <= lastSubPoolId; ++i) {
            require(lockDealNFT.ownerOf(i) == address(this), "invalid owner of sub pool");
            _validProviderInterface(lockDealNFT.poolIdToProvider(i), Bundable._INTERFACE_ID_BUNDABLE);
        }
    }
}
