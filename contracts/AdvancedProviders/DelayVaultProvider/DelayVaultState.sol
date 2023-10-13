// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SimpleProviders/DealProvider/DealProviderState.sol";
import "../../util/CalcUtils.sol";
import "./LastPoolOwnerState.sol";
import "./HoldersSum.sol";

abstract contract DelayVaultState is DealProviderState, LastPoolOwnerState, HoldersSum {
    using CalcUtils for uint256;

    function beforeTransfer(address from, address to, uint256 poolId) external override onlyNFT {
        if (to == address(lockDealNFT))
            // this means it will be withdraw or split
            lastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        else if (from != address(0) && !lockDealNFT.approvedContracts(from)) {
            _handleTransfer(from, to, poolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal returns (uint256 amount) {
        amount = poolIdToAmount[poolId];
        _subHoldersSum(from, amount);
        _addHoldersSum(to, amount, false);
    }

    function getWithdrawPoolParams(uint256 amount, uint8 theType) public view returns (uint256[] memory params) {
        uint256[] memory settings = typeToProviderData[theType].params;
        params = _getWithdrawPoolParams(amount, settings);
    }

    function _getWithdrawPoolParams(
        uint256 amount,
        uint256[] memory settings
    ) internal view returns (uint256[] memory params) {
        uint256 length = settings.length + 1;
        params = new uint256[](length);
        params[0] = amount;
        for (uint256 i = 0; i < settings.length; i++) {
            params[i + 1] = block.timestamp + settings[i];
        }
    }

    //This need to make a new pool without transfering the token, the pool data is taken from the settings
    function withdraw(uint256 tokenId) external override onlyNFT returns (uint256 withdrawnAmount, bool isFinal) {
        address owner = lastPoolOwner[tokenId];
        uint8 theType = userToType[owner];
        uint256 amount = poolIdToAmount[tokenId];
        _createLockNFT(owner, amount, theType, tokenId);
        isFinal = true;
        withdrawnAmount = poolIdToAmount[tokenId] = 0;
        _subHoldersSum(owner, amount);
        _resetTypeIfEmpty(owner);
    }

    function _createLockNFT(address owner, uint256 amount, uint8 theType, uint tokenId) internal {
        ProviderData memory providerData = typeToProviderData[theType];
        uint256 newPoolId = lockDealNFT.mintForProvider(owner, providerData.provider);
        lockDealNFT.cloneVaultId(newPoolId, tokenId);
        uint256[] memory params = getWithdrawPoolParams(amount, theType);
        providerData.provider.registerPool(newPoolId, params);
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) external override onlyNFT {
        address oldOwner = lastPoolOwner[oldPoolId];
        address newOwner = lockDealNFT.ownerOf(newPoolId);
        uint256 amount = poolIdToAmount[oldPoolId].calcAmount(ratio);
        poolIdToAmount[oldPoolId] -= amount;
        poolIdToAmount[newPoolId] = amount;
        if (newOwner != oldOwner) {
            _handleTransfer(oldOwner, newOwner, newPoolId);
        }
    }

    function _resetTypeIfEmpty(address user) internal {
        if (getTotalAmount(user) == 0) {
            userToType[user] = 0; //reset the type
        }
    }

    function getTypeToProviderData(uint8 theType) public view virtual returns (ProviderData memory providerData) {
        providerData = typeToProviderData[theType];
    }
}
