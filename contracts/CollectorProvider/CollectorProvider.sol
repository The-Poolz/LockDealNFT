// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";
import "../ProviderInterface/IDeposit.sol";

contract CollectorProvider is LockDealState, IDeposit {
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        dealProvider = DealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    function deposit(uint256 poolId, uint256 amount)
        public
        override
        onlyProvider
    {
        require(block.timestamp <= startTimes[poolId], "Ended");
        uint256[] memory params = dealProvider.getParams(poolId);
        params[0] += amount;
        dealProvider.registerPool(poolId, params);
    }

    function currentParamsTargetLenght()
        public
        view
        override
        returns (uint256)
    {
        return 1 + dealProvider.currentParamsTargetLenght();
    }

    ///@param params[0] = amount
    ///@param params[1] = startTime
    function _registerPool(
        uint256 poolId,
        uint256[] memory params
    ) internal override {
        require(block.timestamp <= params[1], "Invalid start time");

        startTimes[poolId] = params[1];
        dealProvider.registerPool(poolId, params);
    }

    /**
     * @dev Retrieves the data of the specific pool identified by `poolId`
     * by calling the downstream cascading provider and adding own data.
     */
    function getParams(
        uint256 poolId
    ) public view override returns (uint256[] memory params) {
        uint256[] memory dealProviderParams;
        dealProviderParams = dealProvider.getParams(poolId);

        params = new uint256[](2);
        params[0] = dealProviderParams[0]; // leftAmount
        params[1] = startTimes[poolId]; // startTime
    }
}
