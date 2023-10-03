// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDelayVaultProvider.sol";
import "./IDelayVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DelayVaultMigrator is IDelayVaultData {
    IDelayVaultV1 public oldVault;
    IDelayVaultProvider public newVault;
    address public token;
    address public vaultManager;
    ILockDealNFT public nftContract;

    constructor(IDelayVaultProvider _newVault, IDelayVaultV1 _oldVault, address _vaultManager) {
        newVault = _newVault;
        oldVault = _oldVault;
        token = newVault.Token();
        vaultManager = _vaultManager;
        nftContract = _newVault.nftContract();
    }

    function fullMigrate() external {
        require(oldVault.Allowance(token, msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(token, msg.sender, amount);
        uint256[] memory params = new uint256[](2);
        params[0] = amount;
        params[1] = 1; //allow type change
        IERC20(token).approve(vaultManager, amount);
        newVault.createNewDelayVault(msg.sender, params);
    }

    function getUserV1Amount(address user) public view returns (uint256) {
        (uint256 amount, , , ) = oldVault.VaultMap(newVault.Token(), user);
        return amount;
    }

    function withdrawTokensFromV1Vault() external {
        require(oldVault.Allowance(token, msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(token, msg.sender, amount);
        uint8 theType = newVault.theTypeOf(newVault.getTotalAmount(msg.sender));
        ProviderData memory providerData = newVault.TypeToProviderData(theType);
        IERC20(token).approve(vaultManager, amount);
        uint256 newPoolId = nftContract.mintAndTransfer(
            msg.sender,
            token,
            address(this),
            amount,
            providerData.provider
        );
        uint256[] memory params = newVault.getWithdrawPoolParams(amount, theType);
        providerData.provider.registerPool(newPoolId, params);
    }
}
