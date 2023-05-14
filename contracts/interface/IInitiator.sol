// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInitiator {
    function initiate(
        address owner,
        address token,
        uint[] memory params
    ) external;
}
