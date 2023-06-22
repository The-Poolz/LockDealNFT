// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockVaultManager {
    uint256 public vaultId;

    function depositByToken(
        address,
        address,
        uint
    ) external returns (uint) {
        return ++vaultId;
    }

    function withdrawByVaultId(
        uint _vaultId,
        address to,
        uint _amount
    ) external {
        // do nothing
    }
}
