// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiWithdrawState.sol";
import "../../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";
import "@poolzfinance/poolz-helper-v2/contracts/Array.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MultiWithdrawProvider is MultiWithdrawState, ERC721Holder, IInnerWithdraw {
    constructor(ILockDealNFT nftContract, uint256 _maxPoolsPerTx) {
        name = "MultiWithdrawProvider";
        lockDealNFT = nftContract;
        maxPoolsPerTx = _maxPoolsPerTx;
    }

    function createNewPool(address _owner) external returns (uint256 poolId) {
        poolId = lockDealNFT.mintForProvider(_owner, IProvider(address(this)));
    }

    function withdraw(uint256) external pure returns (uint256 withdrawnAmount, bool isFinal) {
        return (type(uint256).max, true);
    }

    function getInnerIdsArray(uint256, address from) external view override returns (uint256[] memory poolIds) {
        uint256 totalPools = lockDealNFT.balanceOf(from);
        poolIds = new uint256[](totalPools);
        uint256 k = 0;
        for (uint256 i = 0; i < totalPools; ) {
            uint256 _poolId = lockDealNFT.tokenOfOwnerByIndex(from, i);
            if (lockDealNFT.poolIdToProvider(_poolId) != IProvider(address(this))) {
                poolIds[i] = _poolId;
                ++k;
            }
            unchecked {
                ++i;
            }
        }
        poolIds = Array.KeepNElementsInArray(poolIds, k);
    }
}
