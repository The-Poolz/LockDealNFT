// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@dev Interface for the provider contract
///@notice This interface is used by the NFT contract to call the provider contract
interface IProvider {
    function withdraw(
        uint256 itemId
    ) external returns (uint256 withdrawnAmount);

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) external;
}
