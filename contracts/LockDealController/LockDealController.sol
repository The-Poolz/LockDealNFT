// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TimedLockDealProvider/TimedLockDealProvider.sol";

contract LockedDealController {
    BaseLockDealProvider public baseLockDealProvider;
    TimedLockDealProvider public timedLockDealProvider;

    constructor(
        address _baseLockDealProvider,
        address _timedLockDealProvider
    ) {
        baseLockDealProvider = BaseLockDealProvider(_baseLockDealProvider);
        timedLockDealProvider = TimedLockDealProvider(_timedLockDealProvider);
    }


    function mintMixedBundle(
        address tokenAddress,
        uint256[] memory unlockTimes,
        uint256[] memory unlockAmounts,
        uint256[] memory startTimes,
        uint256[] memory finishTimes,
        uint256[] memory startAmounts,
        address[] memory recipients
    ) external {
        require(unlockAmounts.length == startAmounts.length, "Invalid input");
        baseLockDealProvider.createMassPool(tokenAddress, recipients, unlockTimes, unlockAmounts);
        timedLockDealProvider.createMassPool(tokenAddress, recipients, startTimes, finishTimes, startAmounts);
    }

    function mintMixedBundleWrtTime(
        address tokenAddress,
        uint256[] memory unlockTimes,
        uint256[] memory unlockAmounts,
        uint256[] memory startTimes,
        uint256[] memory finishTimes,
        uint256[] memory startAmounts,
        address[] memory recipients
    ) external {
        require(unlockAmounts.length == startAmounts.length, "Invalid input");
        baseLockDealProvider.createPoolsWrtTime(tokenAddress, recipients, unlockTimes, unlockAmounts);
        timedLockDealProvider.createPoolsWrtTime(tokenAddress, recipients, startTimes, finishTimes, startAmounts);
    }

    function Withdraw(uint256 itemId) external {
        (, uint256 baseAmount,) = baseLockDealProvider.itemIdToDeal(itemId);
        (, uint256 timedAmount,) = timedLockDealProvider.itemIdToDeal(itemId);
        if(baseAmount > 0) {
            baseLockDealProvider.withdraw(itemId);
        }
        if(timedAmount > 0) {
            timedLockDealProvider.withdraw(itemId);
        }
    }
}
