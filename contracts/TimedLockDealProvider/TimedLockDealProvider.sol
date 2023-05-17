// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider/Provider.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";

contract TimedLockDealProvider is Provider {
    struct TimedDeal {
        uint256 finishTime;
        uint256 withdrawnAmount;
    }

    mapping(uint256 => TimedDeal) public poolIdToTimedDeal;

    constructor(address nftContract) Provider(nftContract) {}

    function createNewPool(
        address owner,
        address token,
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    )
        external
        notZeroAddress(owner)
        notZeroAddress(token)
        notZeroAmount(amount)
        returns (uint256 poolId)
    {
        require(
            finishTime >= startTime,
            "Finish time should be greater than start time"
        );
        poolId = _createNewPool(
            owner,
            token,
            GetParams(amount, startTime, finishTime)
        );
        //ERC20Helper.TransferInToken(token, msg.sender, amount);
        emit NewPoolCreated(createBasePoolInfo(poolId, owner, token), GetParams(amount, startTime, finishTime));
    }

    function withdraw(
        uint256 itemId
    )
        external
        virtual
        override
        onlyOwnerOrAdmin(itemId)
        returns (uint256 withdrawnAmount)
    {

    }

    function split(
        uint256 itemId,
        uint256 splitAmount,
        address newOwner
    ) external virtual override {

    }

    function GetParams(
        uint256 amount,
        uint256 startTime,
        uint256 finishTime
    ) internal pure returns (uint256[] memory params) {
        params = new uint256[](3);
        params[0] = amount;
        params[1] = startTime;
        params[2] = finishTime;
    }

    function _createNewPool(
        address owner,
        address token,
        uint256[] memory params
    ) internal validParams(params,3) returns (uint256 newItemId) {
        // Assuming params[0] is amount, params[1] is startTime, params[2] is finishTime
        poolIdToTimedDeal[newItemId] = TimedDeal(params[2], 0);
    }
}
