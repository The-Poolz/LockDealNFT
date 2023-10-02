// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IProvider.sol";

abstract contract HoldersSum {
    //this is only the delta
    //the amount is the amount of the pool
    // params[0] = startTimeDelta (empty for DealProvider)
    // params[1] = endTimeDelta (only for TimedLockDealProvider)
    struct ProviderData {
        IProvider provider;
        uint256[] params; // 0 for DealProvider,1 for LockProvider ,2 for TimedDealProvider
        uint256 limit;
    }
    mapping(uint256 => uint8) internal PoolToType;
    mapping(address => uint256[]) public UserToTotalAmount; //thw array will be {typesCount} lentgh
    mapping(uint8 => ProviderData) internal TypeToProviderData; //will be {typesCount} lentgh
    uint8 public typesCount;

    function _addHoldersSum(address user, uint8 theType, uint256 amount) internal {
        uint256 newAmount = UserToTotalAmount[user][theType] + amount;
        _setHoldersSum(user, theType, newAmount);
    }

    function _subHoldersSum(address user, uint8 theType, uint256 amount) internal {
        uint256 oldAmount = UserToTotalAmount[user][theType];
        require(oldAmount >= amount, "amount exceeded");
        uint256 newAmount = oldAmount - amount;
        UserToTotalAmount[user][theType] = newAmount;
    }

    function _setHoldersSum(address user, uint8 theType, uint256 amount) internal {
        uint256[] memory amountsByType = UserToTotalAmount[user];
        require(amount <= TypeToProviderData[theType].limit, "limit exceeded");
        if (amountsByType.length == 0) {
            amountsByType = new uint256[](typesCount);
            UserToTotalAmount[user] = amountsByType;
        }
        UserToTotalAmount[user][theType] = amount;
    }

    function _getHoldersSum(address user, uint8 theType) internal view returns (uint256 amount) {
        amount = UserToTotalAmount[user][theType];
    }

    function getLeftAmount(address owner, uint8 theType) external view returns (uint256) {
        return TypeToProviderData[theType].limit - _getHoldersSum(owner, theType);
    }
}
