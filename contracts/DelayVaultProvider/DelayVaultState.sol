// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/DealProvider/DealProviderState.sol";
import "../SimpleProviders/Provider/ProviderModifiers.sol";
import "./LastPoolOwnerState.sol";

abstract contract DelayVaultState is DealProviderState, ProviderModifiers, LastPoolOwnerState {
    mapping(uint256 => uint8) internal PoolToType;
    mapping(address => uint256[]) public UserToTotalAmount; //thw array will be {typesCount} lentgh
    mapping(uint8 => ProviderData) internal TypeToProviderData; //will be {typesCount} lentgh
    uint8 public typesCount;
    ILockDealNFT public nftContract;
    address public Token;

    //this is only the delta
    //the amount is the amount of the pool
    // params[0] = startTimeDelta (empty for DealProvider)
    // params[1] = endTimeDelta (only for TimedLockDealProvider)
    struct ProviderData {
        IProvider provider;
        uint256[] params; // 0 for DealProvider,1 for LockProvider ,2 for TimedDealProvider
        uint256 limit;
    }

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
        amount = poolIdToAmount[poolId];
        uint256 newAmount = UserToTotalAmount[to][theType] + amount;
        require(newAmount <= TypeToProviderData[theType].limit, "limit exceeded");
        UserToTotalAmount[from][theType] -= amount;
        UserToTotalAmount[to][theType] = newAmount;
    }

    function currentParamsTargetLenght() public view override returns (uint256) {
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
}
