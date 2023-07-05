// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealProvider.sol";
import "../ProviderInterface/IDeposit.sol";
import "../ProviderInterface/IProviderSingleIdRegistrar.sol";

contract CollectorProvider is IDeposit, IProviderSingleIdRegistrar {
    LockDealProvider public lockProvider;

    constructor(/*address _lockDealNFT,*/ address provider) {
        require(
            /*_lockDealNFT != address(0x0) &&*/ provider != address(0x0),
            "invalid address"
        );
        //lockDealNFT = LockDealNFT(_lockDealNFT);
        lockProvider = LockDealProvider(provider);
    }

    function deposit(uint256 poolId, uint256 amount) public override {
        uint256[] memory params = new uint256[](2);
        params[0] += amount;
        params[1] = block.timestamp;
        lockProvider.registerPool(poolId, params);
    }

    function registerPool(uint256 poolId, uint256[] calldata params) external override {
        lockProvider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) external view returns (uint256[] memory params){
        return lockProvider.getParams(poolId);
    }

    function withdraw(
        uint256 poolId,
        uint256 amount
    ) public returns (uint256 withdrawnAmount, bool isFinal) {
        return lockProvider.withdraw(poolId, amount);
    }
}
