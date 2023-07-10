// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";

contract CollateralState is LockDealState, ProviderModifiers {
    function getParams(
        uint256 poolId
    ) public view returns (uint256[] memory params) {
        uint256 mainCoinHolderId = poolId + 3;
        if (lockDealNFT.exist(mainCoinHolderId)) {
            params = new uint256[](2);
            params[0] = dealProvider.getParams(mainCoinHolderId)[0];
            params[1] = startTimes[poolId];
        }
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 2;
    }
}
