// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDelayVaultV1.sol";

contract MockDelayVault is IDelayVaultV1 {
    mapping(address => mapping(address => Vault)) public VaultMap;
    mapping(address => mapping(address => bool)) public Allowance;

    struct Vault {
        uint256 Amount;
        uint256 StartDelay;
        uint256 CliffDelay;
        uint256 FinishDelay;
    }

    // input data for VaultMap
    constructor(address token, Vault[] memory vaults, address[] memory owners) {
        uint256 length = vaults.length;
        require(length == owners.length, "MockDelayVault: wrong input data");
        for (uint256 i = 0; i < length; ++i) {
            VaultMap[token][owners[i]] = vaults[i];
        }
    }

    function CreateNewPool(address token, uint256 startAmount, address owner) external {}

    function approveTokenRedemption(address token, bool status) external {
        Allowance[token][msg.sender] = status;
    }

    function redeemTokensFromVault(address token, address owner, uint256 amount) external {}
}
