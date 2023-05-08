// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TimedLockDealProvider/TimedLockDealProvider.sol";
import "../LockDealNFT/ICustomItemInterface.sol";

contract LockDealBundleMulti {
    ICustomItemInterface public lockDealNFT;

    struct LockDeal {
        address provider;
        uint256 amount;
        uint256 startTime;
        uint256 finishTime;
    }

    struct Recipient {
        address to;
        uint256 amount;
    }

    constructor(address _lockDealNFT) {
        lockDealNFT = ICustomItemInterface(_lockDealNFT);
    }

    function mintBundle(
        address tokenAddress,
        LockDeal[] memory lockDeals,
        Recipient[] memory recipients
    ) external {
        for (uint256 i = 0; i < lockDeals.length; i++) {
            LockDeal memory lockDeal = lockDeals[i];
            if (lockDeal.provider == address(0)) {
                continue;
            }

            for (uint256 j = 0; j < recipients.length; j++) {
                Recipient memory recipient = recipients[j];
                if (lockDeal.finishTime == 0) {
                    BaseLockDealProvider provider = BaseLockDealProvider(lockDeal.provider);
                    provider.mint(recipient.to, tokenAddress, recipient.amount, lockDeal.startTime);
                } else {
                    TimedLockDealProvider provider = TimedLockDealProvider(lockDeal.provider);
                    provider.mint(recipient.to, tokenAddress, recipient.amount, lockDeal.startTime, lockDeal.finishTime);
                }
            }
        }
    }
}
