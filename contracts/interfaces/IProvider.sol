// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@dev Interface for the provider contract
///@notice This interface is used by the NFT contract to call the provider contract
interface IProvider {
    function withdraw(address operator, address from, uint256 tokenId, bytes calldata data) external returns (uint256 withdrawnAmount, bool isFinal);
    function split(uint256 oldPoolId, uint256 newPoolId, uint256 splitAmount) external;
    function registerPool(uint256 poolId, uint256[] calldata params) external;
    function getParams(uint256 poolId) external view returns (uint256[] memory params);
    function getWithdrawableAmount(uint256 poolId) external view returns (uint256);
}
