pragma solidity ^0.8.0;

interface ICustomItemInterface {
    function mint(address to) external;
    function withdraw(uint256 itemId) external;
    function split(uint256 itemId, uint256 splitAmount) external;
    function isRefundable(uint256 itemId) external view returns (bool);
}
