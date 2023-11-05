// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../ERC165/Refundble.sol";
import "./RefundState.sol"; 
import {SphereXProtected} from "@spherex-xyz/contracts/src/SphereXProtected.sol";
 

contract RefundProvider is RefundState, IERC721Receiver , SphereXProtected {
    constructor(ILockDealNFT nftContract, address provider) {
        require(address(nftContract) != address(0x0) && provider != address(0x0), "invalid address");
        lockDealNFT = nftContract;
        collateralProvider = CollateralProvider(provider);
        name = "RefundProvider";
    }

    ///@dev refund implementation
    function onERC721Received(
        address provider,
        address user,
        uint256 poolId,
        bytes calldata
    ) external override sphereXGuardExternal(0xfe8d1ec4) returns (bytes4) {
        require(msg.sender == address(lockDealNFT), "invalid nft contract");
        if (provider == user) {
            uint256 collateralPoolId = poolIdToCollateralId[poolId];
            require(collateralProvider.poolIdToTime(collateralPoolId) > block.timestamp, "too late");
            ISimpleProvider dealProvider = collateralProvider.provider();
            uint256 userDataPoolId = poolId + 1;
            // user withdraws his tokens and will receives refund
            uint256 amount = dealProvider.getParams(userDataPoolId)[0];
            (uint256 withdrawnAmount, ) = dealProvider.withdraw(userDataPoolId, amount);
            collateralProvider.handleRefund(collateralPoolId, user, withdrawnAmount);
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    struct createNewRefundPoolLocals {
        uint256 paramsLength;
        IProvider provider;
        uint256 dataPoolID;
        uint256 collateralPoolId;
    }

    ///@param addresses[0] = owner
    ///@param addresses[1] = token
    ///@param addresses[2] = main coin
    ///@param addresses[3] = provider
    ///@param params[0] = tokenLeftAmount
    ///@param params[params.length - 2] = refundMainCoinAmount
    ///@param params[params.length - 1] = refund finish time
    function createNewRefundPool(
        address[] calldata addresses,
        uint256[] calldata params,
        bytes calldata tokenSignature,
        bytes calldata mainCoinSignature
    ) external sphereXGuardExternal(0x1b5a4f7f) returns (uint256 poolId) {
        createNewRefundPoolLocals memory locals;
        _validAddressLength(addresses.length, 4);
        _validProviderInterface(IProvider(addresses[3]), Refundble._INTERFACE_ID_REFUNDABLE);
        locals.paramsLength = params.length;
        require(locals.paramsLength > 2, "invalid params length");
        locals.provider = IProvider(addresses[3]);
        // create new refund pool | Owner User
        poolId = lockDealNFT.mintForProvider(addresses[0], this);

        // Hold token (data) | Owner Refund Provider
        locals.dataPoolID = lockDealNFT.safeMintAndTransfer(
            address(this),
            addresses[1],
            msg.sender,
            params[0],
            locals.provider,
            tokenSignature
        );
        locals.provider.registerPool(locals.dataPoolID, params);

        // Hold main coin | Project Owner
        locals.collateralPoolId = lockDealNFT.safeMintAndTransfer(
            msg.sender,
            addresses[2],
            msg.sender,
            params[locals.paramsLength - 2],
            collateralProvider,
            mainCoinSignature
        );
        collateralProvider.registerPool(locals.collateralPoolId, params);
        lockDealNFT.cloneVaultId(locals.collateralPoolId + 2, locals.dataPoolID); // clone token data to sub-collateral poolId
        // save refund data
        uint256[] memory refundRegisterParams = new uint256[](currentParamsTargetLenght());
        refundRegisterParams[0] = locals.collateralPoolId;
        _registerPool(poolId, refundRegisterParams);
    }

    ///@param params[0] = collateralId
    function registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) public override onlyProvider validProviderId(poolId) validProviderAssociation(params[0], collateralProvider) sphereXGuardPublic(0xab228ee1, 0xe9a9fce2) {
        require(lockDealNFT.ownerOf(poolId + 1) == address(this), "Must Own poolId+1");
        _registerPool(poolId, params);
    }

    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal validParamsLength(params.length, currentParamsTargetLenght()) sphereXGuardInternal(0x5ea5ccec) {
        poolIdToCollateralId[poolId] = params[0];
        emit UpdateParams(poolId, params);
    }

    ///@dev split tokens and main coins into new pools
    function split(uint256 poolId, uint256 newPoolId, uint256 ratio) external onlyNFT sphereXGuardExternal(0xf27cfa59) {
        uint256[] memory params = new uint256[](currentParamsTargetLenght());
        params[0] = poolIdToCollateralId[poolId];
        _registerPool(newPoolId, params);
        uint256 userPoolId = poolId + 1;
        lockDealNFT.safeTransferFrom(address(this), address(lockDealNFT), userPoolId, abi.encode(ratio));
    }

    ///@dev user withdraws his tokens
    function withdraw(uint256 poolId) public override onlyNFT sphereXGuardPublic(0xb87a92c4, 0x2e1a7d4d) returns (uint256 amountToBeWithdrawed, bool isFinal) {
        uint256 userDataPoolId = poolId + 1;
        IProvider provider = lockDealNFT.poolIdToProvider(userDataPoolId);
        amountToBeWithdrawed = provider.getWithdrawableAmount(userDataPoolId);
        if (collateralProvider.poolIdToTime(poolIdToCollateralId[poolId]) >= block.timestamp) {
            collateralProvider.handleWithdraw(poolIdToCollateralId[poolId], amountToBeWithdrawed);
        }
        isFinal = provider.getParams(userDataPoolId)[0] == amountToBeWithdrawed;
    }
}
