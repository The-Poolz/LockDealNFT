// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DealProvider/DealProvider.sol";

/// @title DealProviderState contract
/// @notice Contains storage variables, structures
contract BaseLockDealState {
    constructor(address _provider) {
        provider = Provider(_provider);
    }

    mapping(uint256 => LockDeal) public itemIdToLockDeal;

    DealProvider public provider;
    struct LockDeal {
        uint256 startTime;
    }

    function getCurrentParamsTargetLenght() public view returns (uint256) {
        return 1;
    }

    function getArray(uint256 startTime) public pure returns (uint256[] memory params) {
        params = new uint256[](1);
        params[0] = startTime;
    }
    function getParametersTargetLenght() public view returns (uint256) {
        return getCurrentParamsTargetLenght() + provider.getParametersTargetLenght();
    }

    function RegisterPool(BasePoolInfo info, uint256[] params) 
    validParams(params,getParametersTargetLenght())
     internal {
        itemIdToLockDeal[itemId] = LockDeal(params[1]);
        provider.RegisterPool(info,params);
    }
}
