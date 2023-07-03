// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../TimedDealProvider/TimedDealProvider.sol";

/// @dev MockProvider is a contract for testing purposes.
contract MockProvider {
    address public provider;
    LockDealNFT public lockDealNFT;

    constructor(address _lockDealNFT, address _provider) {
        lockDealNFT = LockDealNFT(_lockDealNFT);
        provider = _provider;
    }

    function withdraw(uint256 poolId, uint256 amount) public {
        TimedDealProvider(provider).withdraw(poolId, amount);
    }

    function createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) public returns (uint256 poolId) {
        poolId = lockDealNFT.mintAndTransfer(owner, token, owner, params[0], address(this));
        TimedDealProvider(provider).registerPool(poolId, params);
    }

    function getParams(
        uint256 poolId
    ) public view returns (uint256[] memory params) {
        return TimedDealProvider(provider).getParams(poolId);
    }
}
