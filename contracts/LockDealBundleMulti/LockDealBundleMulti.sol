// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TimedLockDealProvider/TimedLockDealProvider.sol";
import "../BaseProvider/BaseLockDealProvider.sol";

contract LockDealBundleMulti {
    //ICustomLockedDeal public lockDealNFT;

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
        //lockDealNFT = ICustomLockedDeal(_lockDealNFT);
    }

    function mintBundle(
        address token,
        LockDeal[] memory lockDeals,
        Recipient[] memory recipients
    ) external {
        //removed, will be made in the future on issue #17
    }
}
