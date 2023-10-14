// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayVaultState.sol";

contract DelayVaultProvider is DelayVaultState {
    constructor(address _token, IMigrator _migrator, ProviderData[] memory _providersData) {
        require(address(_token) != address(0x0), "invalid address");
        require(address(_migrator) != address(0x0), "invalid address");
        require(_providersData.length <= 255, "too many providers");
        name = "DelayVaultProvider";
        token = _token;
        migrator = _migrator;
        lockDealNFT = _migrator.getLockDealNFT();
        _finilize(_providersData);
    }

    ///@param params[0] = amount
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) public override onlyProvider validProviderId(poolId) {
        require(params.length == currentParamsTargetLenght(), "invalid params length");
        _registerPool(poolId, params);
    }

    function _registerPool(uint256 poolId, uint256[] calldata params) internal {
        uint256 amount = params[0];
        address owner = lockDealNFT.ownerOf(poolId);
        _addHoldersSum(owner, amount, owner == msg.sender);
        poolIdToAmount[poolId] = amount;
    }

    function getParams(uint256 poolId) external view override returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = poolIdToAmount[poolId];
    }

    function getWithdrawableAmount(uint256 poolId) external view override returns (uint256 withdrawalAmount) {
        withdrawalAmount = poolIdToAmount[poolId];
    }

    function upgradeType(uint8 newType) public {
        uint8 oldType = userToType[msg.sender];
        uint256 amount = getTotalAmount(msg.sender);
        require(amount > 0, "amount must be bigger than 0");
        require(newType > oldType, "new type must be bigger than the old one");
        require(newType < typesCount, "new type must be smaller than the types count");
        userToType[msg.sender] = newType;
    }

    function createNewDelayVault(address owner, uint256[] calldata params) external returns (uint256 poolId) {
        require(params.length == currentParamsTargetLenght(), "invalid params length");
        require(owner != address(0), "invalid owner address");
        uint256 amount = params[0];
        require(amount > 0, "amount must be bigger than 0");
        poolId = lockDealNFT.mintAndTransfer(owner, token, msg.sender, amount, this);
        _registerPool(poolId, params);
    }
}
