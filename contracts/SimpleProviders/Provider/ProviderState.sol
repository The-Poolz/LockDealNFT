// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";

abstract contract ProviderState is IProvider {
    ///@dev Each provider sets its own name
    string public name;
    ILockDealNFT public lockDealNFT;

    ///@dev each provider decides how many parameters it needs by overriding this function
    function currentParamsTargetLenght() public view virtual returns (uint256) {
        return 1;
    }
}
