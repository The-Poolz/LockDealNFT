// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@poolzfinance/poolz-helper-v2/contracts/interfaces/ILockDealNFT.sol";
import "@poolzfinance/poolz-helper-v2/contracts/interfaces/IBeforeTransfer.sol";

abstract contract ProviderState is IProvider, IBeforeTransfer {
    ///@dev Each provider sets its own name
    string public name;
    ILockDealNFT public lockDealNFT;
    // Mapping to store the last owner of each SimpleProvider pool before a withdrawal
    mapping(uint256 => address) internal lastPoolOwner;

    ///@dev each provider decides how many parameters it needs by overriding this function
    function currentParamsTargetLength() public view virtual returns (uint256) {
        return 1;
    }

    function getSubProvidersPoolIds(uint256) public view virtual override returns (uint256[] memory poolIds) {
        return poolIds;
    }
}
