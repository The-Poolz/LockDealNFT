// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@dev Interface for the provider contract
///@notice This interface is used by the NFT contract to call the provider contract
interface IProvider {
    struct BasePoolInfo {
        uint256 poolId;
        address owner;
        address token;
    }

    function withdraw(
        uint256 poolId
    ) external returns (uint256 withdrawnAmount, bool isFinal);

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external;

    function getData(
        uint256 poolId
    ) external view returns (
        BasePoolInfo memory poolInfo,
        uint256[] memory params
    );
}
