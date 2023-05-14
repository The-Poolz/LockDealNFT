// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TimedLockDealProvider/TimedLockDealProvider.sol";
import "../BaseProvider/BaseLockDealProvider.sol";

contract LockDealBundleMulti is DealProvider, IInitiator {
    constructor(address _lockDealNFT) {
        DealProvider(nftContract);
    }

    mapping(uint256 => Bandle) public poolIdToBandle;
    struct Bandle {
        uint256 First;
    }

    struct LockDeal {
        address provider;
        uint256[] params;
    }

    struct Recipient {
        address to;
        uint256 amount;
    }

    function mintBundle(
        address token,
        Recipient[] memory recipients,
        LockDeal[] memory lockDeals
    ) external {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            Recipient memory recipient = recipients[i];
            uint256 userTotal = 0;
            for (uint256 j = 0; j < lockDeals.length; j++) {
                LockDeal memory lockDeal = lockDeals[j];
                userTotal += recipient.amount;
                IInitiator(lockDeal.provider).initiate(
                    address(this),
                    token,
                    lockDeal.params
                );
            }
            uint256 newItem = _createNewPool(recipient.to, token, userTotal);
            poolIdToBandle[newItem] = Bandle(newItem);
            totalAmount += userTotal;
        }
        // TODO: Transfer the total amount tokens
    }
}
