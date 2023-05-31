// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/IProviderEvents.sol";

///@dev Interface for the provider contract
///@notice This interface is used by the NFT contract to call the provider contract
interface IProvider {
    function withdraw(
        uint256 poolId
    ) external returns (uint256 withdrawnAmount);

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external;

    function getData(
        uint256 poolId
    ) external view returns (
        IProviderEvents.BasePoolInfo memory poolInfo,
        uint256[] memory params
    );
}
