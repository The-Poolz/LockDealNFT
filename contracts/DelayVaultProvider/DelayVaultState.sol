// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProviderState.sol";
import "./LastPoolOwnerState.sol";
import "./HoldersSum.sol";
import "../util/CalcUtils.sol";

abstract contract DelayVaultState is DealProviderState, LastPoolOwnerState, HoldersSum {
    using CalcUtils for uint256;
    ILockDealNFT public nftContract;
    address public Token;

    function _beforeTransfer(address from, address to, uint256 poolId) internal override {
        if (to == address(lockDealNFT))
            // this means it will be withdraw or split
            LastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        else {
            _handleTransfer(from, to, poolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal returns (uint256 amount) {
        uint8 theType = PoolToType[poolId];
        _subHoldersSum(from, theType, amount);
        _addHoldersSum(to, theType, amount);
    }

    function currentParamsTargetLenght() public pure override returns (uint256) {
        return 2;
    }

    function _getWithdrawPoolParams(uint256 poolId, uint8 theType) internal view returns (uint256[] memory params) {
        uint256[] memory settings = TypeToProviderData[theType].params;
        params = _getWithdrawPoolParams(poolId, settings);
    }

    function _getWithdrawPoolParams(
        uint256 poolId,
        uint256[] memory settings
    ) internal view returns (uint256[] memory params) {
        uint256 length = settings.length + 1;
        params = new uint256[](length);
        params[0] = poolIdToAmount[poolId];
        for (uint256 i = 0; i < settings.length; i++) {
            params[i + 1] = block.timestamp + settings[i];
        }
    }

    function withdraw(uint256 tokenId) external override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        uint8 theType = PoolToType[tokenId];
        address owner = LastPoolOwner[tokenId];
        uint256 newPoolId = nftContract.mintForProvider(owner, TypeToProviderData[theType].provider);
        uint256[] memory params = _getWithdrawPoolParams(tokenId, theType);
        TypeToProviderData[theType].provider.registerPool(newPoolId, params);
        isFinal = true;
        withdrawnAmount = poolIdToAmount[tokenId] = 0;
        _subHoldersSum(owner, theType, params[0]);
        //This need to make a new pool without transfering the token, the pool data is taken from the settings
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) external override onlyNFT {
        address oldOwner = LastPoolOwner[oldPoolId];
        address newOwner = nftContract.ownerOf(newPoolId);
        uint256 amount = poolIdToAmount[oldPoolId].calcAmount(ratio);
        poolIdToAmount[oldPoolId] -= amount;
        poolIdToAmount[newPoolId] = amount;
        PoolToType[newPoolId] = PoolToType[oldPoolId];
        if (newOwner != oldOwner) {
            _handleTransfer(oldOwner, newOwner, oldPoolId);
        }
    }
}
