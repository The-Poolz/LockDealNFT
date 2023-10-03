// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/ILockDealNFT.sol";
import "./IDelayVaultProvider.sol"; //need to be interface with the 2 functions
import "./IDelayVaultV1.sol";

abstract contract DelayVaultMigrator {
    IDelayVaultV1 public oldVault;
    IDelayVaultProvider public newVault;

    constructor(IDelayVaultProvider _newVault, IDelayVaultV1 _oldVault) {
        newVault = _newVault;
        oldVault = _oldVault;
    }

    function fullMigrate() external {
        require(oldVault.Allowance(newVault.Token(), msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(newVault.Token(), msg.sender, amount);
        uint256[] memory params = new uint256[](2);
        params[0] = amount;
        params[1] = 1; //allow type change
        newVault.createNewDelayVault(msg.sender, params);
    }

    function getUserV1Amount(address user) public view returns (uint256) {
        (uint256 amount, , , ) = oldVault.VaultMap(newVault.Token(), user);
        return amount;
    }
}
