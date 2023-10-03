// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SimpleProviders/Provider/ProviderModifiers.sol";
import "./MigratorV1/IDelayVaultProvider.sol";
import "./MigratorV1/IMigrator.sol";

abstract contract HoldersSum is ProviderModifiers, IDelayVaultData {
    //this is only the delta
    //the amount is the amount of the pool
    // params[0] = startTimeDelta (empty for DealProvider)
    // params[1] = endTimeDelta (only for TimedLockDealProvider)
    event HoldersSumChanged(address indexed user, uint256 amount);
    mapping(address => uint256) public UserToAmount; //Each user got total amount
    mapping(address => uint8) public UserToType; //Each user got type, can go up. wjem withdraw to 0, its reset
    mapping(uint8 => ProviderData) public TypeToProviderData; //will be {typesCount} lentgh
    uint8 public typesCount; //max type + 1

    IMigrator public Migrator;

    function getTotalAmount(address user) public view returns (uint256) {
        return UserToAmount[user] + Migrator.getUserV1Amount(user);
    }

    function theTypeOf(uint256 amount) public view returns (uint8 theType) {
        for (uint8 i = 0; i < typesCount; i++) {
            if (amount <= TypeToProviderData[i].limit) {
                theType = i;
                break;
            }
        }
    }

    function _addHoldersSum(address user, uint256 amount, bool allowTypeUpgrade) internal {
        uint256 newAmount = UserToAmount[user] + amount;
        _setHoldersSum(user, newAmount, allowTypeUpgrade);
    }

    function _subHoldersSum(address user, uint256 amount) internal {
        uint256 oldAmount = UserToAmount[user];
        require(oldAmount >= amount, "amount exceeded");
        uint256 newAmount = oldAmount - amount;
        _setHoldersSum(user, newAmount, false);
    }

    function _setHoldersSum(address user, uint256 amount, bool allowTypeUpgrade) internal {
        uint8 newType = theTypeOf(getTotalAmount(user) + amount);
        if (allowTypeUpgrade) {
            // Upgrade the user type if the newType is greater
            if (newType > UserToType[user]) {
                UserToType[user] = newType;
            }
        } else {
            // Ensure the type doesn't change if upgrades are not allowed
            require(newType <= UserToType[user], "type must be the same or lower");
        }
        UserToAmount[user] = amount;
        emit HoldersSumChanged(user, amount);
    }

    function _finilize(ProviderData[] memory _providersData) internal {
        typesCount = uint8(_providersData.length);
        uint256 limit = 0;
        for (uint8 i = 0; i < typesCount; i++) {
            limit = _setTypeToProviderData(i, limit, _providersData[i]);
        }
    }

    function _setTypeToProviderData(
        uint8 theType,
        uint256 lastLimit,
        ProviderData memory item
    ) internal returns (uint256 limit) {
        require(address(item.provider) != address(0x0), "invalid address");
        require(item.provider.currentParamsTargetLenght() == item.params.length + 1, "invalid params length");
        limit = item.limit;
        require(limit >= lastLimit, "limit must be bigger or equal than the previous on");
        TypeToProviderData[theType] = item;
        if (theType == typesCount - 1) {
            TypeToProviderData[theType].limit = type(uint256).max; //the last one is the max, token supply is out of the scope
        }
    }
}
