// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockDealNFT/LockDealNFT.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./DealProviderModifiers.sol";
import "./IDealProvierEvents.sol";

abstract contract DealProvider is
    IDealProvierEvents,
    DealProviderModifiers,
    ERC20Helper,
    Ownable
{
    constructor(address _nftContract) {
        nftContract = LockDealNFT(_nftContract);
    }

    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public validParams(msg.sender, 1) returns (uint256 newPoolId) {
        newPoolId = nftContract.totalSupply();
        poolIdToDeal[newPoolId] = Deal(token, params[0]);
        nftContract.mint(owner);
        emit NewPoolCreated(
            createBasePoolInfo(newPoolId, owner, token),
            params
        );
    }

    /// @dev no use of revert to make sure the loop will work
    function withdraw(
        uint256 poolId,
        uint256 withdrawalAmount
    ) public returns (uint256 withdrawnAmount) {
        if (
            withdrawalAmount > 0 &&
            providers[msg.sender].status &&
            withdrawalAmount <= poolIdToDeal[poolId].startAmount
        ) {
            poolIdToDeal[poolId].startAmount -= withdrawalAmount;
            TransferToken(
                poolIdToDeal[poolId].token,
                nftContract.ownerOf(poolId),
                withdrawalAmount
            );
            emit TokenWithdrawn(
                createBasePoolInfo(
                    poolId,
                    nftContract.ownerOf(poolId),
                    poolIdToDeal[poolId].token
                ),
                withdrawalAmount,
                poolIdToDeal[poolId].startAmount
            );
            withdrawnAmount = withdrawalAmount;
        }
    }

    function split(
        uint256 poolId,
        uint256 splitAmount
    ) public onlyApprovedProvider(msg.sender) {}

    // function split(
    //     uint256 poolId,
    //     uint256 splitAmount,
    //     address newOwner
    // ) public onlyApprovedProvider(msg.sender) {
    //     Deal storage deal = poolIdToDeal[poolId];
    //     require(
    //         deal.startAmount >= splitAmount,
    //         "Split amount exceeds the available amount"
    //     );
    //     deal.startAmount -= splitAmount;
    //     // uint256 newPoolId = createNewPool(newOwner, deal.token, splitAmount);
    //     // emit PoolSplit(
    //     //     createBasePoolInfo(poolId, nftContract.ownerOf(poolId), deal.token),
    //     //     createBasePoolInfo(newPoolId, newOwner, deal.token),
    //     //     splitAmount
    //     // );
    // }

    function getDeal(uint256 poolId) public view returns (address, uint256) {
        return (poolIdToDeal[poolId].token, poolIdToDeal[poolId].startAmount);
    }

    function createBasePoolInfo(
        uint256 poolId,
        address owner,
        address token
    ) internal pure returns (BasePoolInfo memory poolInfo) {
        poolInfo.PoolId = poolId;
        poolInfo.Owner = owner;
        poolInfo.Token = token;
    }

    function setProviderSettings(
        address provider,
        uint256 paramsLength,
        bool status
    ) external onlyOwner {
        providers[provider].status = status;
        providers[provider].paramsLength = paramsLength;
    }
}
