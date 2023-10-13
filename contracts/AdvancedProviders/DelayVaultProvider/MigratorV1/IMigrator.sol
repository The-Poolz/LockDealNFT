// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/ILockDealNFT.sol";

interface IMigrator {
    function getUserV1Amount(address user) external view returns (uint256 amount);

    function getLockDealNFT() external view returns (ILockDealNFT);
}
