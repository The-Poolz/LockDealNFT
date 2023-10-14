// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayMigratorState.sol";
import "../../../interfaces/IMigrator.sol";
import "../../../interfaces/ILockDealV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract DelayVaultMigrator is DelayMigratorState, IMigrator, ILockDealV2 {
    constructor(ILockDealNFT _nft, IDelayVaultV1 _oldVault) {
        require(address(_oldVault) != address(0), "DelayVaultMigrator: Invalid old delay vault contract");
        require(address(_nft) != address(0), "DelayVaultMigrator: Invalid lock deal nft contract");
        oldVault = _oldVault;
        lockDealNFT = _nft;
    }

    function finilize(IDelayVaultProvider _newVault) external {
        require(owner != address(0), "DelayVaultMigrator: already initialized");
        require(msg.sender == owner, "DelayVaultMigrator: not owner");
        require(
            ERC165Checker.supportsInterface(address(_newVault), type(IDelayVaultProvider).interfaceId),
            "DelayVaultMigrator: Invalid new delay vault contract"
        );
        newVault = _newVault;
        token = newVault.token();
        vaultManager = lockDealNFT.vaultManager();
        owner = address(0); // Set owner to zero address
    }

    //this option is to get tokens from the DelayVaultV1 and deposit them to the DelayVaultV2 (LockDealNFT, v3)
    function fullMigrate() external afterInit {
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
    function withdrawTokensFromV1Vault() external afterInit {
        require(oldVault.Allowance(token, msg.sender), "DelayVaultMigrator: not allowed");
        uint256 amount = getUserV1Amount(msg.sender);
        oldVault.redeemTokensFromVault(token, msg.sender, amount);
        uint8 theType = newVault.theTypeOf(newVault.getTotalAmount(msg.sender));
        IDelayVaultProvider.ProviderData memory providerData = newVault.getTypeToProviderData(theType);
        IERC20(token).approve(address(vaultManager), amount);
        uint256 newPoolId = lockDealNFT.mintAndTransfer(
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

    function CreateNewPool(
        address _Token, //token to lock address
        uint256, // Until what time the pool will start
        uint256, //Before CliffTime can't withdraw tokens
        uint256, //Until what time the pool will end
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        address _Owner // Who the tokens belong to
    ) external payable override afterInit {
        require(msg.sender == address(oldVault), "DelayVaultMigrator: not DelayVaultV1");
        uint8 theType = newVault.theTypeOf(newVault.getTotalAmount(_Owner));
        IDelayVaultProvider.ProviderData memory providerData = newVault.getTypeToProviderData(theType);
        IERC20(token).transferFrom(msg.sender, address(this), _StartAmount);
        IERC20(token).approve(address(vaultManager), _StartAmount);
        uint256 newPoolId = lockDealNFT.mintAndTransfer(
            _Owner,
            _Token,
            address(this),
            _StartAmount,
            providerData.provider
        );
        uint256[] memory params = newVault.getWithdrawPoolParams(_StartAmount, theType);
        providerData.provider.registerPool(newPoolId, params);
    }

    function getLockDealNFT() external view override returns (ILockDealNFT) {
        return lockDealNFT;
    }
}
