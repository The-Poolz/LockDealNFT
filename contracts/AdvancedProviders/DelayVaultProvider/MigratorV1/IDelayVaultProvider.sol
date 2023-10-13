// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/IProvider.sol";
import "../../../interfaces/ILockDealNFT.sol";

interface IDelayVaultProvider {
    struct ProviderData {
        IProvider provider;
        uint256[] params; // 0 for DealProvider,1 for LockProvider ,2 for TimedDealProvider
        uint256 limit;
    }

    function createNewDelayVault(address owner, uint256[] memory params) external returns (uint256 poolId);

    function token() external view returns (address);

    function theTypeOf(uint256 amount) external view returns (uint8);

    function getTotalAmount(address user) external view returns (uint256);

    function getTypeToProviderData(uint8 theType) external view returns (ProviderData memory providerData);

    function getWithdrawPoolParams(uint256 amount, uint8 theType) external view returns (uint256[] memory params);
}
