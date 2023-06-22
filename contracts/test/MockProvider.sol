// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../TimedDealProvider/TimedDealProvider.sol";

/// @dev MockProvider is a contract for testing purposes.
contract MockProvider {
    address public provider;

    constructor(address _provider) {
        provider = _provider;
    }

    function withdraw(uint256 poolId, uint256 amount) public {
        TimedDealProvider(provider).withdraw(poolId, amount);
    }

    function createNewPool(
        address /** owner **/,
        address /** token **/,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        TimedDealProvider(provider).registerPool(poolId, params);
    }

    function getData(
        uint256 poolId
    )
        public
        view
        returns (
            IDealProvierEvents.BasePoolInfo memory poolInfo,
            uint256[] memory params
        )
    {
        return TimedDealProvider(provider).getData(poolId);
    }
}
