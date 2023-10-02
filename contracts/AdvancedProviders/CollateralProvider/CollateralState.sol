// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SimpleProviders/LockProvider/LockDealState.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../SimpleProviders/Provider/ProviderModifiers.sol";
import "../../interfaces/IInnerWithdraw.sol";

abstract contract CollateralState is LockDealState, IInnerWithdraw, IERC165, ProviderModifiers {
    mapping(uint256 => uint256) public poolIdToRateToWei;

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        (, , uint256 mainCoinHolderId) = getInnerIds(poolId);
        params = new uint256[](2);
        params[0] = provider.getParams(mainCoinHolderId)[0];
        params[1] = poolIdToTime[poolId];
    }

    function getInnerIdsArray(uint256 poolId) public view override returns (uint256[] memory ids) {
        if (poolIdToTime[poolId] < block.timestamp) {
            ids = new uint256[](3);
            (ids[0], ids[1], ids[2]) = getInnerIds(poolId);
        } else {
            ids = new uint256[](2);
            (, ids[0], ids[1]) = getInnerIds(poolId);
        }
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 3;
    }

    function getInnerIds(
        uint256 poolId
    ) internal pure returns (uint256 mainCoinCollectorId, uint256 tokenHolderId, uint256 mainCoinHolderId) {
        mainCoinCollectorId = poolId + 1;
        tokenHolderId = poolId + 2;
        mainCoinHolderId = poolId + 3;
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256 withdrawalAmount) {
        if (lockDealNFT.poolIdToProvider(poolId) == this) {
            (uint256 mainCoinCollectorId, , uint256 mainCoinHolderId) = getInnerIds(poolId);
            withdrawalAmount = lockDealNFT.getWithdrawableAmount(mainCoinCollectorId);
            if (poolIdToTime[poolId] <= block.timestamp) {
                withdrawalAmount += lockDealNFT.getWithdrawableAmount(mainCoinHolderId);
            }
        }
    }

    ///@dev Collateral can't be Refundble or Bundleble
    /// Override basic provider supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IInnerWithdraw).interfaceId;
    }
}
