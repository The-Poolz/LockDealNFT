// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "../Provider/Provider.sol";
import "../DealProvider/DealProviderState.sol";

contract DealProvider is Provider, DealProviderState, ERC20Helper {
    constructor(address nftContract) Provider(nftContract) {}
    function CreatePool(
        address owner,
        address token,
        uint256 amount
    ) external returns (uint256 poolId) {
        poolId = mint(owner);
        TransferInToken(token, msg.sender, amount);
        emit NewPoolCreated(
            createBasePoolInfo(poolId, owner, token),
            getArray(amount)
        );
    }
    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external override {}

    function withdraw(uint256 itemId) external override returns (uint256) {}
}
