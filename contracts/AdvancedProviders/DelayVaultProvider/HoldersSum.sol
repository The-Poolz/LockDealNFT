// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../SimpleProviders/Provider/ProviderModifiers.sol";
import "./MigratorV1/IDelayVaultProvider.sol";
import "./MigratorV1/IMigrator.sol";

abstract contract HoldersSum is ProviderModifiers, IDelayVaultData {
    //this is only the delta
    //the amount is the amount of the pool
    // params[0] = startTimeDelta (empty for DealProvider)
    // params[1] = endTimeDelta (only for TimedLockDealProvider)
    mapping(address => uint256) public userToAmount; //Each user got total amount
    mapping(address => uint8) public userToType; //Each user got type, can go up. wjem withdraw to 0, its reset
    mapping(uint8 => ProviderData) public typeToProviderData; //will be {typesCount} length
    uint8 public typesCount; //max type + 1
    address public token;
    IMigrator public migrator;

    event VaultValueChanged(address indexed token, address indexed owner, uint256 amount);

    function getTotalAmount(address user) public view returns (uint256) {
        return userToAmount[user] + migrator.getUserV1Amount(user);
    }

    function theTypeOf(uint256 amount) public view returns (uint8 theType) {
        for (uint8 i = 0; i < typesCount; ++i) {
            if (amount <= typeToProviderData[i].limit) {
                theType = i;
                break;
            }
        }
    }

    function _addHoldersSum(address user, uint256 amount, bool allowTypeUpgrade) internal {
        uint256 newAmount = userToAmount[user] + amount;
        _setHoldersSum(user, newAmount, allowTypeUpgrade);
    }

    function _subHoldersSum(address user, uint256 amount) internal {
        uint256 oldAmount = userToAmount[user];
        require(oldAmount >= amount, "amount exceeded");
        uint256 newAmount = oldAmount - amount;
        _setHoldersSum(user, newAmount, false);
    }

    function _setHoldersSum(address user, uint256 newAmount, bool allowTypeUpgrade) internal {
        uint8 newType = theTypeOf(migrator.getUserV1Amount(user) + newAmount);
        if (allowTypeUpgrade) {
            _upgradeUserTypeIfGreater(user, newType);
        } else {
            _updateUserTypeIfMatchesV1(user, newType);
            // Ensure the type doesn't change if upgrades are not allowed
            require(newType <= userToType[user], "type must be the same or lower");
        }
        userToAmount[user] = newAmount;
        emit VaultValueChanged(token, user, newAmount);
    }

    function _upgradeUserTypeIfGreater(address user, uint8 newType) internal {
        if (newType > userToType[user]) {
            userToType[user] = newType;
        }
    }

    function _updateUserTypeIfMatchesV1(address user, uint8 newType) internal {
        if (newType == theTypeOf(migrator.getUserV1Amount(user))) {
            userToType[user] = newType;
        }
    }

    function _finilize(ProviderData[] memory _providersData) internal {
        typesCount = uint8(_providersData.length);
        uint256 limit = 0;
        for (uint8 i = 0; i < typesCount; ++i) {
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
        typeToProviderData[theType] = item;
        if (theType == typesCount - 1) {
            typeToProviderData[theType].limit = type(uint256).max; //the last one is the max, token supply is out of the scope
        }
    }
}
