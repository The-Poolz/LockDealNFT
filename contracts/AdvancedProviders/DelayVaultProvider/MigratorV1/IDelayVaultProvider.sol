// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/IProvider.sol";
import "../../../interfaces/ILockDealNFT.sol";

interface IDelayVaultProvider {
    function createNewDelayVault(address owner, uint256[] memory params) external;

    function Token() external view returns (address);

    function getLeftAmount(address owner, uint8 theType) external view returns (uint256);

    function theTypeOf(uint256 amount) external view returns (uint8);

    function nftContract() external view returns (ILockDealNFT);

    function getTotalAmount(address user) external view returns (uint256);

    function TypeToProviderData(uint8 theType) external view returns (IDelayVaultData.ProviderData memory providerData);

    function getWithdrawPoolParams(uint256 amount, uint8 theType) external view returns (uint256[] memory params);
}

interface IDelayVaultData {
    struct ProviderData {
        IProvider provider;
        uint256[] params; // 0 for DealProvider,1 for LockProvider ,2 for TimedDealProvider
        uint256 limit;
    }
}
