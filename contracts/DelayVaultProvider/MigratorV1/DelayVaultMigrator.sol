// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";
import "../DelayVaultProvider.sol"; //need to be interface with the 2 functions

abstract contract IOldDelayVault {
    //need to be interface with the functions, on other file
    function redeemTokensFromVault(address _token, address _owner, uint256 _amount) external virtual;

    mapping(address => mapping(address => bool)) public Allowance; //token, owner
    mapping(address => mapping(address => Vault)) public VaultMap; //token, owner
    struct Vault {
        uint256 Amount;
        uint256 StartDelay;
        uint256 CliffDelay;
        uint256 FinishDelay;
    }
}

contract DelayVaultMigrator {
    IOldDelayVault public oldVault;
    DelayVaultProvider public newVault;

    constructor(DelayVaultProvider _newVault, IOldDelayVault _oldVault) {
        newVault = _newVault;
        oldVault = _oldVault;
    }

    function Migrate() external {
        require(oldVault.Allowance(newVault.Token(), msg.sender), "not allowed");
        (uint256 amount, , , ) = oldVault.VaultMap(newVault.Token(), msg.sender);
        oldVault.redeemTokensFromVault(newVault.Token(), msg.sender, amount);
        uint8 theType = 0;
        while (amount > 0) {
            uint256[] memory params = new uint256[](2);
            uint256 leftAmount = newVault.getLeftAmount(msg.sender, theType);
            params[0] = amount > leftAmount ? leftAmount : amount;
            params[1] = uint256(theType);
            amount -= params[0];
            newVault.createNewDelayVault(msg.sender, params);
            ++theType;
        }
    }
}
