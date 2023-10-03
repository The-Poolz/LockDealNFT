// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayVaultState.sol";

contract DelayVaultProvider is DelayVaultState {
    constructor(address _token, ILockDealNFT _nftContract, ProviderData[] memory _providersData) {
        require(address(_token) != address(0x0), "invalid address");
        require(address(_nftContract) != address(0x0), "invalid address");
        require(_providersData.length <= 255, "too many providers");
        name = "DelayVaultProvider";
        Token = _token;
        lockDealNFT = _nftContract;
        typesCount = uint8(_providersData.length);
        uint256 limit = 0;
        for (uint8 i = 0; i < typesCount; i++) {
            limit = _setTypeToProviderData(i, limit, _providersData[i]);
        }
    }

    function registerPool(uint256 poolId, uint256[] calldata params) public override onlyProvider {
        uint8 theType = uint8(params[1]);
        uint256 amount = params[0];
        address owner = nftContract.ownerOf(poolId);
        require(PoolToType[poolId] == 0, "pool already registered");
        require(params.length == 2, "invalid params length");
        PoolToType[poolId] = theType;
        _addHoldersSum(owner, theType, amount);
        poolIdToAmount[poolId] = amount;
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        params = new uint256[](2);
        params[0] = poolIdToAmount[poolId];
        params[1] = uint256(PoolToType[poolId]);
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        withdrawalAmount = poolIdToAmount[poolId];
    }

    function upgradeTypes(uint256[] calldata poolIds, uint8 newType) public {
        for (uint256 i = 0; i < poolIds.length; i++) {
            upgradeType(poolIds[i], newType);
        }
    }

    function upgradeType(uint256 PoolId, uint8 newType) public {
        uint8 oldType = PoolToType[PoolId];
        uint256 amount = poolIdToAmount[PoolId];
        require(amount > 0, "pool is empty");
        require(nftContract.poolIdToProvider(PoolId) == this, "need to be THIS provider");
        require(msg.sender == nftContract.ownerOf(PoolId), "only the Owner can upgrade the type");
        require(newType > oldType, "new type must be bigger than the old one");
        require(newType < typesCount, "new type must be smaller than the types count");
        PoolToType[PoolId] = newType;
        _subHoldersSum(msg.sender, oldType, amount);
        _addHoldersSum(msg.sender, newType, amount);
    }

    function createNewDelayVault(address owner, uint256[] calldata params) external returns (uint256 PoolId) {
        uint256 amount = params[0];
        uint8 theType = uint8(params[1]);
        require(theType <= typesCount, "invalid type");
        require(amount > 0, "amount must be bigger than 0");
        PoolId = nftContract.mintAndTransfer(owner, Token, msg.sender, amount, this);
        registerPool(PoolId, params);
    }
}
