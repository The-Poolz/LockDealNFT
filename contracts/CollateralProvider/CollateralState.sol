// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";
import "../ProviderInterface/IProvider.sol";

abstract contract CollateralState is LockDealState, ProviderModifiers, IProvider {
    function getParams(
        uint256 poolId
    ) public override view returns (uint256[] memory params) {
        (, , uint256 mainCoinHolderId) = getInnerIds(poolId);
        if (lockDealNFT.exist(mainCoinHolderId)) {
            params = new uint256[](2);
            params[0] = dealProvider.getParams(mainCoinHolderId)[0];
            params[1] = startTimes[poolId];
        }
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 2;
    }

    function getInnerIds(uint256 poolId) internal pure returns(uint256 mainCoinCollectorId, uint256 tokenHolderId, uint256 mainCoinHolderId) {
        mainCoinCollectorId = poolId + 1;
        tokenHolderId = poolId + 2;
        mainCoinHolderId = poolId + 3;
    }
}
