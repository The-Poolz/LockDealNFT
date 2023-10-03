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

    function beforeTransfer(address from, address to, uint256 poolId) external override onlyNFT {
        if (to == address(lockDealNFT))
            // this means it will be withdraw or split
            LastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        else {
            _handleTransfer(from, to, poolId);
        }
    }

    function _handleTransfer(address from, address to, uint256 poolId) internal returns (uint256 amount) {
        amount = poolIdToAmount[poolId];
        _subHoldersSum(from, amount);
        _addHoldersSum(to, amount, false);
    }

    function getWithdrawPoolParams(uint256 amount, uint8 theType) public view returns (uint256[] memory params) {
        uint256[] memory settings = TypeToProviderData[theType].params;
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
        address owner = LastPoolOwner[tokenId];
        uint8 theType = UserToType[owner];
        uint256 amount = poolIdToAmount[tokenId];
        _createLockNFT(owner, amount, theType, tokenId);
        isFinal = true;
        withdrawnAmount = poolIdToAmount[tokenId] = 0;
        _subHoldersSum(owner, amount);
        if (getTotalAmount(owner) == 0) {
            UserToType[owner] = 0; //reset the type
        }
    }

    function _createLockNFT(address owner, uint256 amount, uint8 theType, uint tokenId) internal {
        ProviderData memory providerData = TypeToProviderData[theType];
        uint256 newPoolId = nftContract.mintForProvider(owner, providerData.provider);
        nftContract.copyVaultId(tokenId, newPoolId);
        uint256[] memory params = getWithdrawPoolParams(amount, theType);
        providerData.provider.registerPool(newPoolId, params);
    }

    function split(uint256 oldPoolId, uint256 newPoolId, uint256 ratio) external override onlyNFT {
        address oldOwner = LastPoolOwner[oldPoolId];
        address newOwner = nftContract.ownerOf(newPoolId);
        uint256 amount = poolIdToAmount[oldPoolId].calcAmount(ratio);
        poolIdToAmount[oldPoolId] -= amount;
        poolIdToAmount[newPoolId] = amount;
        if (newOwner != oldOwner) {
            _handleTransfer(oldOwner, newOwner, oldPoolId);
        }
    }
}
