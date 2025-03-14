// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../LockProvider/LockDealState.sol";
import "../DealProvider/DealProviderState.sol";
import "../Provider/BasicProvider.sol";
import "@poolzfinance/poolz-helper-v2/contracts/CalcUtils.sol";
import "@poolzfinance/poolz-helper-v2/contracts/LastPoolOwnerState.sol";

contract TimedDealProvider is LockDealState, DealProviderState, BasicProvider, LastPoolOwnerState {
    using CalcUtils for uint256;

    /**
     * @dev Contract constructor.
     * @param _lockDealNFT The address of the LockDealNFT contract.
     * @param _provider The address of the LockProvider contract.
     */
    constructor(ILockDealNFT _lockDealNFT, address _provider) {
        require(address(_lockDealNFT) != address(0x0) && _provider != address(0x0), "invalid address");
        provider = ISimpleProvider(_provider);
        lockDealNFT = _lockDealNFT;
        name = "TimedDealProvider";
    }

    function _withdraw(
        uint256 poolId,
        uint256 amount
    ) internal override firewallProtectedSig(0x9e2bf22c) returns (uint256 withdrawnAmount, bool isFinal) {
        if (amount == 0) return (0, false);
        isFinal = true;
        withdrawnAmount = amount;
        uint256[] memory params = provider.getParams(poolId);
        uint256 remainingAmount = params[0] - amount;
        if (remainingAmount > 0 && lastPoolOwner[poolId] != address(0)) {
            // create immutable NFT
            uint256 newPoolId = lockDealNFT.mintForProvider(
                lastPoolOwner[poolId],
                lockDealNFT.poolIdToProvider(poolId)
            );
            // clone vault id
            lockDealNFT.cloneVaultId(newPoolId, poolId);
            // register new pool
            params[0] = remainingAmount;
            provider.registerPool(newPoolId, params);
            poolIdToTime[newPoolId] = poolIdToTime[poolId];
            poolIdToAmount[newPoolId] = poolIdToAmount[poolId];
            delete lastPoolOwner[poolId];
        }
        // Reset and update the original pool
        params[0] = 0;
        provider.registerPool(poolId, params);
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

    function split(uint256 lockDealNFTPoolId, uint256 newPoolId, uint256 ratio) external firewallProtected onlyProvider {
        provider.split(lockDealNFTPoolId, newPoolId, ratio);
        uint256 newPoolStartAmount = poolIdToAmount[lockDealNFTPoolId].calcAmount(ratio);
        poolIdToAmount[newPoolId] = newPoolStartAmount;
        poolIdToTime[newPoolId] = poolIdToTime[lockDealNFTPoolId];
        // save startAmount and FinishTime to the newly created pool from the old pool
        poolIdToAmount[newPoolId + 1] = poolIdToAmount[lockDealNFTPoolId] - newPoolStartAmount;
        poolIdToTime[newPoolId + 1] = poolIdToTime[lockDealNFTPoolId];
    }

    ///@param params[0] = leftAmount = startAmount (leftAmount & startAmount must be same while creating pool)
    ///@param params[1] = startTime
    ///@param params[2] = finishTime
    function _registerPool(uint256 poolId, uint256[] calldata params) internal override firewallProtectedSig(0xb99c642c) {
        require(params[2] >= params[1], "Finish time should be greater than start time");
        poolIdToTime[poolId] = params[2];
        poolIdToAmount[poolId] = params[0];
        provider.registerPool(poolId, params);
    }

    function getParams(uint256 poolId) public view override returns (uint256[] memory params) {
        uint256[] memory lockDealProviderParams;
        lockDealProviderParams = provider.getParams(poolId);

        params = new uint256[](4);
        params[0] = lockDealProviderParams[0]; // leftAmount
        params[1] = lockDealProviderParams[1]; // startTime
        params[2] = poolIdToTime[poolId]; // finishTime
        params[3] = poolIdToAmount[poolId]; // startAmount
    }

    function currentParamsTargetLength() public view override(IProvider, ProviderState) returns (uint256) {
        return 1 + provider.currentParamsTargetLength();
    }

    /**
     * @dev Executes before a transfer, updating state based on the transfer details.
     * @param from Sender address.
     * @param to Receiver address.
     * @param poolId Pool identifier.
     */
    function beforeTransfer(
        address from,
        address to,
        uint256 poolId
    ) external virtual override firewallProtected onlyNFT {
        if (to == address(lockDealNFT)) {
            // this means it will be withdraw or split
            lastPoolOwner[poolId] = from; //this is the only way to know the owner of the pool
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(BasicProvider, LastPoolOwnerState) returns (bool) {
        return BasicProvider.supportsInterface(interfaceId) || LastPoolOwnerState.supportsInterface(interfaceId);
    }
}
