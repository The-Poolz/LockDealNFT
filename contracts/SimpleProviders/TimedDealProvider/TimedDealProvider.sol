// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimedProviderState.sol";

contract TimedDealProvider is BasicProvider, TimedProviderState {
    /**
     * @dev Contract constructor.
     * @param nft The address of the LockDealNFT contract.
     * @param provider The address of the LockProvider contract.
     */
    constructor(address nft, address provider) {
        require(
            nft != address(0x0) && provider != address(0x0),
            "invalid address"
        );
        lockDealProvider = LockDealProvider(provider);
        lockDealNFT = LockDealNFT(nft);
    }

    /// @dev use revert only for permissions
    function withdraw(
        address, address, uint256 poolId, bytes calldata
    ) public override onlyProvider returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = _withdraw(poolId, getWithdrawableAmount(poolId));
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override returns (uint256 withdrawnAmount, bool isFinal) {
        (withdrawnAmount, isFinal) = lockDealProvider.withdraw(poolId, amount);
    }

    function getWithdrawableAmount(uint256 poolId) public view override returns (uint256) {
        uint256[] memory params = getParams(poolId);
        uint256 leftAmount = params[0];
        uint256 startTime = params[1];
        uint256 finishTime = params[2];
        uint256 startAmount = params[3];

        if (block.timestamp < startTime) return 0;
        if (finishTime <= block.timestamp) return leftAmount;

        uint256 totalPoolDuration = finishTime - startTime;
        uint256 timePassed = block.timestamp - startTime;
        uint256 debitableAmount = (startAmount * timePassed) / totalPoolDuration;
        return debitableAmount - (startAmount - leftAmount);
    }

    function _calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return tokenBValue != 0 ? (tokenAValue * 1e18) / tokenBValue : 0;
    }

    function _calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return rate != 0 ? amount * 1e18 / rate : 0;
    }

    function split(
        uint256 oldPoolId,
        uint256 newPoolId,
        uint256 splitAmount
    ) public onlyProvider {
        uint256 leftAmount = lockDealProvider.dealProvider().getWithdrawableAmount(oldPoolId);
        uint256 rate = _calcRate(leftAmount, splitAmount);
        lockDealProvider.split(oldPoolId, newPoolId, splitAmount);
        uint256 newPoolStartAmount = _calcAmount(poolIdToTimedDeal[oldPoolId].startAmount, rate);
        poolIdToTimedDeal[oldPoolId].startAmount -= newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].startAmount = newPoolStartAmount;
        poolIdToTimedDeal[newPoolId].finishTime = poolIdToTimedDeal[oldPoolId].finishTime;
    }

    ///@param params[0] = leftAmount = startAmount (leftAmount & startAmount must be same while creating pool)
    ///@param params[1] = startTime
    ///@param params[2] = finishTime
    function _registerPool(
        uint256 poolId,
        uint256[] calldata params
    ) internal override {
        require(
            params[2] >= params[1],
            "Finish time should be greater than start time"
        );
        poolIdToTimedDeal[poolId].finishTime = params[2];
        poolIdToTimedDeal[poolId].startAmount = params[0];
        lockDealProvider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        uint256[] memory lockDealProviderParams;
        lockDealProviderParams = lockDealProvider.getParams(poolId);

        params = new uint256[](4);
        params[0] = lockDealProviderParams[0];  // leftAmount
        params[1] = lockDealProviderParams[1];  // startTime
        params[2] = poolIdToTimedDeal[poolId].finishTime; // finishTime
        params[3] = poolIdToTimedDeal[poolId].startAmount; // startAmount
    }

    function currentParamsTargetLenght() public override view returns (uint256) {
        return 1 + lockDealProvider.currentParamsTargetLenght();
    }
}