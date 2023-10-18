// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/IDelayVaultProvider.sol";
import "../../../interfaces/IDelayVaultV1.sol";
import "../../../interfaces/IMigrator.sol";

abstract contract DelayMigratorState is IMigrator {
    IDelayVaultV1 public oldVault;
    IDelayVaultProvider public newVault;
    ILockDealNFT public lockDealNFT;
    IVaultManager public vaultManager;
    address public token;
    address public owner = msg.sender; // Initialize owner at declaration

    modifier afterInit() {
        _afterInit();
        _;
    }

    ///@dev internal function to save small amounts of gas
    function _afterInit() internal view {
        require(owner == address(0), "DelayVaultMigrator: not initialized");
    }
}
