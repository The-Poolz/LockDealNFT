// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDelayVaultProvider.sol";
import "./IDelayVaultV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DelayVaultMigrator is IDelayVaultData {
    IDelayVaultV1 public oldVault;
    IDelayVaultProvider public newVault;
    address public token;
    IVaultManager public vaultManager;
    ILockDealNFT public nftContract;
    bool public isInitialized;
    address public owner = msg.sender; // Initialize owner at declaration

    constructor(IDelayVaultV1 _oldVault) {
        oldVault = _oldVault;
    }

    function finilize(IDelayVaultProvider _newVault) external {
        require(owner != address(0), "DelayVaultMigrator: already initialized");
        require(msg.sender == owner, "DelayVaultMigrator: not owner");
        newVault = _newVault;
        token = newVault.Token();
        nftContract = newVault.nftContract();
        vaultManager = nftContract.vaultManager();
        owner = address(0); // Set owner to zero address
    }

    //this option is to get tokens from the DelayVaultV1 and deposit them to the DelayVaultV2 (LockDealNFT, v3)
    function fullMigrate() external {
        require(oldVault.Allowance(token, msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(token, msg.sender, amount);
        uint256[] memory params = new uint256[](2);
        params[0] = amount;
        params[1] = 1; //allow type change
        IERC20(token).approve(address(vaultManager), amount);
        newVault.createNewDelayVault(msg.sender, params);
    }

    //this option is to get tokens from the DelayVaultV1 and deposit them to the LockDealNFT (v3)
    function withdrawTokensFromV1Vault() external {
        require(oldVault.Allowance(token, msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(token, msg.sender, amount);
        uint8 theType = newVault.theTypeOf(newVault.getTotalAmount(msg.sender));
        ProviderData memory providerData = newVault.TypeToProviderData(theType);
        IERC20(token).approve(address(vaultManager), amount);
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

    function getUserV1Amount(address user) public view returns (uint256 amount) {
        (amount, , , ) = oldVault.VaultMap(token, user);
    }
}
