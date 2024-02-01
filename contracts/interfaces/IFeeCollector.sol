// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCollector {
    // Function to get the value of feeCollected
    function feeCollected() external view returns (bool);
}
