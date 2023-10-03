// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelayVaultV1 {
    function redeemTokensFromVault(address _token, address _owner, uint256 _amount) external;

    function Allowance(address _token, address _owner) external view returns (bool);

    function VaultMap(address _token, address _owner) external view returns (uint256, uint256, uint256, uint256);
}
