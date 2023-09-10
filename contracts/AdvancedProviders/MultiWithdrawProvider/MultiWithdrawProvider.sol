// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransactionState.sol";
import "../../AdvancedProviders/CollateralProvider/IInnerWithdraw.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

contract MultiWithdrawProvider is TransactionState, IInnerWithdraw, IERC721Receiver{

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

    function getWithdrawableAmountOfToken(address _owner, address _token) external view returns(uint256 amount) {
        uint256[] memory poolIds = getAllPoolsOfOwner(_owner);
        for(uint256 i = 0; i < poolIds.length;) {
            address tokenAddress = lockDealNFT.tokenOf(poolIds[i]);
            if(tokenAddress == _token) {
                amount += lockDealNFT.poolIdToProvider(poolIds[i]).getWithdrawableAmount(poolIds[i]);
            }
            unchecked { ++i; }
        }
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
            (uint256 withdrawnAmount, bool isFinal) = lockDealNFT.withdrawForProvider(poolId);
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

    function withdraw(uint256 poolId)
        external
        onlyNFT
        validataPoolId(poolId)
        returns (uint256 withdrawnAmount, bool isFinal)
    {
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

    function getInnerIdsArray(uint256 poolId)
        external view override
        validataPoolId(poolId)
        returns (uint256[] memory ids)
    {
        require(iterator != 0, "Invalid Iterator");
        ids = new uint256[](uniqueVaultIds.length);
        for(uint256 i = 0; i < uniqueVaultIds.length; ) {
            ids[i] = mintedPoolId;
            unchecked { ++i; }
        }
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        require(operator == address(this), "invalid nft contract");
        return IERC721Receiver.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IInnerWithdraw).interfaceId;
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