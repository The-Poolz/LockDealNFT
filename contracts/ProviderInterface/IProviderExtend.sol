// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/IDealProvierEvents.sol";

interface IProviderExtend {
    function registerPool(uint256 poolId, address owner, address token, uint256[] memory params) external;
}