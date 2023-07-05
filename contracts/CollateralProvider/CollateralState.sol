// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TimedDealProvider/TimedProviderState.sol";

///@title hold the information of the collateral
contract CollateralState is TimedProviderState {    
    /// @dev the rate of the collateral in wei, example: 100 tokens = 10 usd, 10/100 = 0.1 usd to token => 1e17 in wei
    /// `TimedProviderState` give us here the FinishTime and StartAmount of the collateral
    mapping(uint256 => uint256) public rateInWei;
}