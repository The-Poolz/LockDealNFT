// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CalcUtils {
    function calcRate(uint256 tokenAValue, uint256 tokenBValue) internal pure returns (uint256) {
        return (tokenAValue * 1e18) / tokenBValue;
    }

    function calcAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
        return (amount * 1e18) / rate;
    }
}