// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockVaultManager {
    function DepositByToken(
        address _tokenAddress,
        address from,
        uint _amount
    ) external returns (uint vaultId) {
        // do nothing
    }

    function WithdrawByVaultId(
        uint _vaultId,
        address to,
        uint _amount
    ) external {
        // do nothing
    }
}
