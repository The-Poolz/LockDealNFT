// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdvancedProviders/DelayVaultProvider/MigratorV1/IMigrator.sol";

contract MockDelayMigrator is IMigrator {
    function getUserV1Amount(address) external pure returns (uint256 amount) {
        amount = 0;
    }
}
