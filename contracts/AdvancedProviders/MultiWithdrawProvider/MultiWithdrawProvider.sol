// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransactionState.sol";
import "../../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";

contract MultiWithdrawProvider is TransactionState, IInnerWithdraw{

    constructor(ILockDealNFT nftContract, uint256 _maxPoolsPerTx) {
        name = "MultiWithdrawProvider";
        lockDealNFT = nftContract;
        maxPoolsPerTx = _maxPoolsPerTx;
    }

    function multiWithdrawAllPoolsOfOwner(address _owner)
        external
        onlyAdminOrNftOwner(_owner)
    {
        uint256[] memory poolIds = getAllPoolsOfOwner(_owner);
        uint256 mintedPoolId = lockDealNFT.mintForProvider(_owner, IProvider(address(this)));
        setTransactionState(poolIds, mintedPoolId, _owner);
        lockDealNFT.transferFrom(_owner, address(lockDealNFT), mintedPoolId);
        clearTransactionState();
    }

    function setTransactionState(uint256[] memory poolIds, uint256 _mintedPoolId, address _owner) private {
        mintedPoolId = _mintedPoolId;
        for(uint256 i = 0; i < poolIds.length;) {
            uint256 poolId = poolIds[i];
            uint256 vaultId = lockDealNFT.getData(poolId).vaultId;
            if(vaultIdToPoolId[vaultId] == 0) {
                uniqueVaultIds.push(vaultId);
                vaultIdToPoolId[vaultId] = poolId; // only need to store the first poolId
            }
            (uint256 withdrawnAmount, bool isFinal) = lockDealNFT.poolIdToProvider(poolId).withdraw(poolId);
            vaultIdToSum[vaultId] += withdrawnAmount;
            if(isFinal){
                lockDealNFT.transferFrom(_owner, address(this), poolId);
            }
            unchecked { ++i; }
        }
    }

    function clearTransactionState() private {
        for(uint256 i = 0; i < uniqueVaultIds.length; ) {
            delete vaultIdToSum[uniqueVaultIds[i]];
            delete vaultIdToPoolId[uniqueVaultIds[i]];
            unchecked { ++i; }
        }
        delete uniqueVaultIds;
        iterator = 0;
        mintedPoolId = 0;
    }

    function withdraw(uint256 poolId) external returns (uint256 withdrawnAmount, bool isFinal){
        require(poolId != 0, "Invalid poolId");
        require(poolId == mintedPoolId, "Invalid poolId");
        if(iterator == 0){
            unchecked{ ++iterator; }
            return (type(uint256).max, true);
        }
        uint256 currentVaultId = uniqueVaultIds[iterator - 1];
        lockDealNFT.copyVaultId(vaultIdToPoolId[currentVaultId], mintedPoolId);
        withdrawnAmount = vaultIdToSum[currentVaultId];
        isFinal = false;
        unchecked{ ++iterator; }
    }

    function getInnerIdsArray(uint256 poolId) external view override returns (uint256[] memory ids){
        require(poolId != 0, "Invalid poolId");
        require(poolId == mintedPoolId, "Invalid poolId");
        require(iterator == 0, "Invalid Iterator");
        ids = new uint256[](uniqueVaultIds.length);
        for(uint256 i = 0; i < uniqueVaultIds.length; ) {
            ids[i] = mintedPoolId;
            unchecked { ++i; }
        }
    }

    function getAllPoolsOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 totalPools = lockDealNFT.balanceOf(_owner);
        uint256[] memory poolIds = new uint256[](totalPools);
        for(uint256 i = 0; i < totalPools; ) {
            poolIds[i] = lockDealNFT.tokenOfOwnerByIndex(_owner, i);
            unchecked { ++i; }
        }
        return poolIds;
    }

}